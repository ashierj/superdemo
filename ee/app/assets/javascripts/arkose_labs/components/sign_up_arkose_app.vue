<script>
import { uniqueId } from 'lodash';
import { logError } from '~/lib/logger';
import { createAlert } from '~/alert';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import { initArkoseLabsScript } from '../init_arkose_labs_script';
import {
  VERIFICATION_LOADING_MESSAGE,
  VERIFICATION_REQUIRED_MESSAGE,
  VERIFICATION_TOKEN_INPUT_NAME,
  CHALLENGE_CONTAINER_CLASS,
} from '../constants';

export default {
  name: 'SignUpArkoseApp',
  components: {
    DomElementListener,
  },
  props: {
    formSelector: {
      type: String,
      required: true,
    },
    publicKey: {
      type: String,
      required: true,
    },
    domain: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      arkoseLabsIframeShown: false,
      arkoseLabsContainerClass: uniqueId(CHALLENGE_CONTAINER_CLASS),
      arkoseToken: '',
      errorAlert: null,
      arkoseChallengeBypassed: false,
    };
  },
  async mounted() {
    try {
      await this.initArkoseLabs();
    } catch (error) {
      this.bypassArkoseOnFailure(error);
    }
  },
  methods: {
    showVerificationError() {
      let message = VERIFICATION_LOADING_MESSAGE;

      if (this.arkoseLabsIframeShown) {
        message = VERIFICATION_REQUIRED_MESSAGE;
      }

      this.errorAlert = createAlert({ message });
      window.scrollTo({ top: 0 });
    },
    onArkoseLabsIframeShown() {
      this.arkoseLabsIframeShown = true;
    },
    async initArkoseLabs() {
      const arkoseObject = await initArkoseLabsScript({
        publicKey: this.publicKey,
        domain: this.domain,
      });

      arkoseObject.setConfig({
        mode: 'inline',
        selector: `.${this.arkoseLabsContainerClass}`,
        onShown: this.onArkoseLabsIframeShown,
        onCompleted: this.passArkoseLabsChallenge,
        onError: this.bypassArkoseOnFailure,
      });
    },
    passArkoseLabsChallenge(response) {
      this.arkoseToken = response.token;
    },
    bypassArkoseOnFailure(error) {
      logError('ArkoseLabs initialization error', error);

      this.arkoseChallengeBypassed = true;
    },
    onSubmit(e) {
      this.errorAlert?.dismiss();

      if (this.arkoseChallengeBypassed) {
        return;
      }

      if (!this.arkoseToken) {
        this.showVerificationError();

        e.preventDefault();
        e.stopPropagation();
      }
    },
  },
  VERIFICATION_LOADING_MESSAGE,
  VERIFICATION_REQUIRED_MESSAGE,
  VERIFICATION_TOKEN_INPUT_NAME,
};
</script>

<template>
  <div>
    <dom-element-listener :selector="formSelector" @submit="onSubmit" />
    <input
      v-model="arkoseToken"
      :name="$options.VERIFICATION_TOKEN_INPUT_NAME"
      type="hidden"
      data-testid="arkose-labs-token-input"
    />
    <div
      v-show="arkoseLabsIframeShown"
      class="gl-display-flex gl-justify-content-center"
      :class="arkoseLabsContainerClass"
      data-testid="arkose-labs-challenge"
    ></div>
  </div>
</template>
