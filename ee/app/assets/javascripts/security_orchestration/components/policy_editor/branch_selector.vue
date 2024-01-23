<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlDisclosureDropdown,
  GlListboxItem,
  GlTruncate,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { mapExceptionsListBoxItem } from 'ee/security_orchestration/components/policy_editor/utils';
import BranchSelectorPopover from './branch_selector_popover.vue';
import { BRANCH_TYPES, BRANCH_TYPES_ITEMS, PROTECTED_BRANCH } from './constants';

const BRANCH_SELECTOR_UNSELECTED = 'branch-selector-unselected';
const BRANCH_SELECTOR_SELECTED = 'branch-selector-selected';

export default {
  BRANCH_SELECTOR_UNSELECTED,
  BRANCH_SELECTOR_SELECTED,
  BRANCH_TYPES_ITEMS,
  name: 'BranchSelector',
  i18n: {
    buttonAnotherText: __('Add another branch'),
    buttonDoneText: __('Done'),
    buttonClearAllText: __('Clear all'),
    header: s__('SecurityOrchestration|Exception branches'),
    noBranchesText: s__('SecurityOrchestration|No branches yet'),
    toggleText: s__('SecurityOrchestration|Choose exception branches'),
    popoverDescription: s__(
      'SecurityOrchestration|Fill in branch name with project name in the format of %{boldStart}branch-name@project-path,%{boldEnd} separate with `,`',
    ),
  },
  components: {
    BranchSelectorPopover,
    GlButton,
    GlCollapsibleListbox,
    GlDisclosureDropdown,
    GlListboxItem,
    GlTruncate,
  },
  props: {
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedExceptions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    const selectedBranchType = this.selectedExceptions?.[0]?.type || '';

    return {
      selectedBranchType,
      showPopover: false,
      branches: this.selectedExceptions.map(mapExceptionsListBoxItem),
    };
  },
  computed: {
    container() {
      return this.hasBranches ? BRANCH_SELECTOR_SELECTED : BRANCH_SELECTOR_UNSELECTED;
    },
    target() {
      return this.hasBranches ? BRANCH_SELECTOR_SELECTED : BRANCH_SELECTOR_UNSELECTED;
    },
    isProtectedBranch() {
      return this.selectedBranchType === PROTECTED_BRANCH;
    },
    popoverTitle() {
      return BRANCH_TYPES[this.selectedBranchType] || BRANCH_TYPES[PROTECTED_BRANCH];
    },
    mappedToYamlFormatBranches() {
      return this.branches.map(({ name, fullPath }) => {
        if (fullPath) {
          return {
            name,
            full_path: fullPath,
            type: this.selectedBranchType,
          };
        }

        return name;
      });
    },
    hasBranches() {
      return this.branches?.length > 0;
    },
    toggleText() {
      return this.branches.map(({ name }) => name).join(', ') || this.$options.i18n.toggleText;
    },
  },
  methods: {
    finishEditing() {
      this.showPopover = false;

      this.$emit('select-branches', this.mappedToYamlFormatBranches);
      this.$refs.dropdown.close();
    },
    selectBranchType(key) {
      this.selectedBranchType = key;
      this.refreshPopover();
    },
    refreshPopover() {
      this.showPopover = false;

      this.$nextTick(() => {
        this.showPopover = true;
      });
    },
    selectBranches(branches) {
      this.branches = branches;
      this.showPopover = false;
    },
    unselectBranch({ name, fullPath }) {
      this.branches = this.branches.filter(
        (branch) => branch.name !== name || branch.fullPath !== fullPath,
      );
    },
    onResetButtonClicked() {
      this.branches = [];
      this.$emit('select-branches', []);
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown
      ref="dropdown"
      fluid-width
      :toggle-text="toggleText"
      @hidden="finishEditing"
    >
      <template #header>
        <div class="gl-display-flex gl-align-items-center gl-p-4 gl-min-h-8 gl-border-b">
          <div class="gl-flex-grow-1 gl-font-weight-bold gl-font-sm gl-pr-2">
            {{ $options.i18n.header }}
          </div>

          <gl-button
            v-if="hasBranches"
            category="tertiary"
            class="gl-focus-inset-border-2-blue-400! gl-flex-shrink-0 gl-font-sm! gl-px-2! gl-py-2! gl-w-auto! gl-m-0! gl-max-w-50p gl-text-overflow-ellipsis"
            data-testid="reset-button"
            @click="onResetButtonClicked"
          >
            {{ $options.i18n.buttonClearAllText }}
          </gl-button>
        </div>
      </template>

      <div class="gl-w-full">
        <template v-if="!hasBranches">
          <div
            class="gl-pl-7 gl-pr-4 gl-pt-2 gl-font-base gl-text-gray-600 security-policies-popover-content-height"
            data-testid="empty-state"
          >
            {{ $options.i18n.noBranchesText }}
          </div>
        </template>
        <template v-else>
          <gl-listbox-item
            v-for="(item, index) in branches"
            :key="`${item.name}_${index}`"
            is-check-centered
            is-selected
            @select="unselectBranch(item)"
          >
            <gl-truncate :text="item.name" />
            <p v-if="item.fullPath" class="gl-text-gray-700 gl-font-sm gl-m-0 gl-mt-1">
              <gl-truncate position="middle" :text="item.fullPath" />
            </p>
          </gl-listbox-item>
        </template>
      </div>

      <template #footer>
        <div class="gl-py-2 gl-px-4 gl-display-flex gl-justify-content-end">
          <gl-collapsible-listbox
            v-if="!hasBranches"
            :id="$options.BRANCH_SELECTOR_UNSELECTED"
            :items="$options.BRANCH_TYPES_ITEMS"
            :toggle-text="popoverTitle"
            :selected="0"
            variant="confirm"
            size="small"
            @select="selectBranchType"
          />

          <div v-else :id="$options.BRANCH_SELECTOR_SELECTED">
            <gl-button data-testid="add-button" size="small" @click="refreshPopover">
              {{ $options.i18n.buttonAnotherText }}
            </gl-button>
            <gl-button
              data-testid="done-button"
              variant="confirm"
              size="small"
              @click="finishEditing"
            >
              {{ $options.i18n.buttonDoneText }}
            </gl-button>
          </div>
        </div>
      </template>
    </gl-disclosure-dropdown>

    <branch-selector-popover
      v-if="showPopover"
      :container="container"
      :target="target"
      :branches="branches"
      :has-validation="isGroup"
      :for-protected-branches="isProtectedBranch"
      :show="showPopover"
      @add-branches="selectBranches"
    />
  </div>
</template>
