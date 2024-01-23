<script>
import { GlButton, GlFormTextarea, GlPopover, GlSprintf } from '@gitlab/ui';
import { uniqBy } from 'lodash';
import { s__, __, sprintf } from '~/locale';
import {
  mapExceptionsListBoxItem,
  validateBranchProjectFormat,
  mapBranchesToString,
} from 'ee/security_orchestration/components/policy_editor/utils';
import { BRANCH_TYPES, REGULAR_BRANCH, PROTECTED_BRANCH } from './constants';

export default {
  i18n: {
    buttonText: __('Add'),
    popoverErrorMessage: s__(
      'SecurityOrchestration|Add project full path after @ to following branches: %{branches}',
    ),
    popoverDuplicateErrorMessage: s__('SecurityOrchestration|Please remove duplicated values'),
    popoverDescription: s__(
      'SecurityOrchestration|Fill in branch name with project name in the format of %{boldStart}branch-name@project-path,%{boldEnd} separate with `,`',
    ),
  },
  name: 'BranchSelectorPopover',
  components: {
    GlButton,
    GlFormTextarea,
    GlPopover,
    GlSprintf,
  },
  inject: ['namespacePath'],
  props: {
    branches: {
      type: Array,
      required: false,
      default: () => [],
    },
    container: {
      type: String,
      required: false,
      default: '',
    },
    forProtectedBranches: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasValidation: {
      type: Boolean,
      required: false,
      default: false,
    },
    placement: {
      type: String,
      required: false,
      default: 'right',
    },
    show: {
      type: Boolean,
      required: false,
      default: false,
    },
    target: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      loading: false,
      hasDuplicates: false,
      showPopover: this.show,
      parsedBranches: this.branches,
      parsedWithErrorsBranches: [],
      protectedBranches: [],
    };
  },
  computed: {
    convertedToStringBranches() {
      return mapBranchesToString(this.branches);
    },
    defaultProjectName() {
      return this.hasValidation ? undefined : this.namespacePath;
    },
    errorMessage() {
      return sprintf(this.$options.i18n.popoverErrorMessage, {
        branches: this.parsedWithErrorsBranches.join(' '),
      });
    },
    popoverTitle() {
      return BRANCH_TYPES[this.selectedBranchType] || BRANCH_TYPES[PROTECTED_BRANCH];
    },
    hasValidationError() {
      return this.parsedWithErrorsBranches.length && this.hasValidation;
    },
    selectedBranchType() {
      return this.forProtectedBranches ? PROTECTED_BRANCH : REGULAR_BRANCH;
    },
  },
  watch: {
    show(newVal) {
      this.showPopover = newVal;
    },
  },
  methods: {
    parseBranches(branches) {
      const split = branches?.split(/[ ,]+/).filter(Boolean) || [];

      this.parsedWithErrorsBranches = [];

      this.parsedBranches = split.map((item) => {
        const [name, fullPath = this.defaultProjectName] = item.split('@');

        return {
          name,
          fullPath,
          value: item,
        };
      });
    },
    selectBranches() {
      this.parsedWithErrorsBranches = this.parsedBranches
        .filter(({ value }) => !validateBranchProjectFormat(value))
        .map(({ name }) => name);
      this.hasDuplicates =
        uniqBy(this.parsedBranches, 'value').length !== this.parsedBranches.length;
      if (this.hasValidationError || this.hasDuplicates) return;

      const parsedSelectedBranches = this.parsedBranches
        .map(mapExceptionsListBoxItem)
        .filter(({ name }) => Boolean(name));
      this.$emit('add-branches', parsedSelectedBranches);
    },
  },
};
</script>

<template>
  <gl-popover
    triggers="manual"
    show-close-button
    :css-classes="['security-policies-popover-max-width']"
    :container="container"
    :placement="placement"
    :target="target"
    :show.sync="showPopover"
    :title="popoverTitle"
  >
    <p>
      <gl-sprintf :message="$options.i18n.popoverDescription">
        <template #bold="{ content }">
          <b>{{ content }}</b>
        </template>
      </gl-sprintf>
    </p>

    <gl-form-textarea
      :value="convertedToStringBranches"
      class="security-policies-textarea-min-height"
      :no-resize="false"
      @input="parseBranches"
    />

    <p v-if="hasValidationError" data-testid="validation-error" class="gl-my-2 gl-text-red-500">
      {{ errorMessage }}
    </p>

    <p v-if="hasDuplicates" data-testid="duplicate-error" class="gl-my-2 gl-text-red-500">
      {{ $options.i18n.popoverDuplicateErrorMessage }}
    </p>

    <div class="gl-display-flex gl-justify-content-end">
      <gl-button class="gl-mt-2" variant="confirm" size="small" @click="selectBranches">
        {{ $options.i18n.buttonText }}
      </gl-button>
    </div>
  </gl-popover>
</template>
