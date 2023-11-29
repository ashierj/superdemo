<script>
import { uniqueId } from 'lodash';
import { initArkoseLabsScript } from '../init_arkose_labs_script';
import { CHALLENGE_CONTAINER_CLASS } from '../constants';

export default {
  name: 'PhoneVerificationArkoseApp',
  props: {
    publicKey: {
      type: String,
      required: true,
    },
    domain: {
      type: String,
      required: true,
    },
    resetSession: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      arkoseLabsIframeShown: false,
      arkoseLabsContainerClass: uniqueId(CHALLENGE_CONTAINER_CLASS),
      arkoseObject: null,
    };
  },
  watch: {
    resetSession: {
      immediate: true,
      handler(reset) {
        if (reset) {
          this.resetArkoseSession();
        }
      },
    },
  },
  async mounted() {
    await this.initArkoseLabs();
  },
  methods: {
    onArkoseLabsIframeShown() {
      this.arkoseLabsIframeShown = true;
    },
    async initArkoseLabs() {
      this.arkoseObject = await initArkoseLabsScript({
        publicKey: this.publicKey,
        domain: this.domain,
      });

      this.arkoseObject.setConfig({
        mode: 'inline',
        selector: `.${this.arkoseLabsContainerClass}`,
        onShown: this.onArkoseLabsIframeShown,
        onCompleted: this.passArkoseLabsChallenge,
      });
    },
    passArkoseLabsChallenge(response) {
      const arkoseToken = response.token;

      this.$emit('challenge-solved', arkoseToken);
    },
    resetArkoseSession() {
      this.arkoseObject?.reset();
    },
  },
};
</script>

<template>
  <div
    v-show="arkoseLabsIframeShown"
    class="gl-display-flex gl-justify-content-center"
    :class="arkoseLabsContainerClass"
    data-testid="arkose-labs-challenge"
  ></div>
</template>
