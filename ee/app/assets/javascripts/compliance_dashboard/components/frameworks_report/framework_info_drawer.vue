<script>
import {
  GlDrawer,
  GlBadge,
  GlButton,
  GlLabel,
  GlLink,
  GlAccordion,
  GlAccordionItem,
  GlTruncate,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

export default {
  name: 'FrameworkInfoDrawer',
  components: {
    GlBadge,
    GlDrawer,
    GlButton,
    GlLabel,
    GlLink,
    GlAccordion,
    GlAccordionItem,
    GlTruncate,
  },
  inject: ['groupSecurityPoliciesPath'],
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    framework: {
      type: Object,
      required: false,
      default: null,
    },
  },
  emits: ['edit', 'close'],
  computed: {
    showDrawer() {
      return Boolean(this.framework);
    },
    getContentWrapperHeight() {
      return getContentWrapperHeight();
    },
    frameworkSettingsPath() {
      return this.framework.webUrl;
    },
    defaultFramework() {
      return Boolean(this.framework.default);
    },
    associatedProjectsTitle() {
      return `${this.$options.i18n.associatedProjects} (${this.framework.projects.nodes.length})`;
    },
    policies() {
      return [
        ...this.framework.scanExecutionPolicies.nodes,
        ...this.framework.scanResultPolicies.nodes,
      ];
    },
    policiesTitle() {
      return `${this.$options.i18n.policies} (${this.policies.length})`;
    },
  },
  methods: {
    getPolicyEditUrl(policy) {
      const { urlParameter } = Object.values(POLICY_TYPE_COMPONENT_OPTIONS).find(
        // eslint-disable-next-line no-underscore-dangle
        (o) => o.typeName === policy.__typename,
      );

      return `${this.groupSecurityPoliciesPath}/${policy.name}/edit?type=${urlParameter}`;
    },
  },
  DRAWER_Z_INDEX,
  i18n: {
    defaultFramework: s__('ComplianceFrameworksReport|Default'),
    editFramework: s__('ComplianceFrameworksReport|Edit framework'),
    frameworkDescription: s__('ComplianceFrameworksReport|Description'),
    associatedProjects: s__('ComplianceFrameworksReport|Associated Projects'),
    policies: s__('ComplianceFrameworksReport|Policies'),
  },
};
</script>

<template>
  <gl-drawer
    :open="showDrawer"
    :header-height="getContentWrapperHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template v-if="framework" #title>
      <div style="max-width: 350px">
        <h2 class="gl-mt-0">
          <gl-truncate :text="framework.name" with-tooltip />
          <gl-label
            v-if="defaultFramework"
            :background-color="framework.color"
            :title="$options.i18n.defaultFramework"
            size="sm"
          />
        </h2>
        <gl-button
          class="gl-my-3"
          category="primary"
          variant="confirm"
          @click="$emit('edit', framework)"
        >
          {{ $options.i18n.editFramework }}
        </gl-button>
      </div>
    </template>

    <template v-if="framework" #default>
      <div>
        <gl-accordion :auto-collapse="false" :header-level="3">
          <gl-accordion-item :title="$options.i18n.frameworkDescription" visible :header-level="2">
            {{ framework.description }}
          </gl-accordion-item>
          <gl-accordion-item
            v-if="framework.projects.nodes.length"
            :title="associatedProjectsTitle"
          >
            <div
              v-for="associatedProject in framework.projects.nodes"
              :key="associatedProject.id"
              class="gl-m-2"
            >
              <gl-link :href="associatedProject.webUrl">{{ associatedProject.name }}</gl-link>
            </div>
          </gl-accordion-item>
          <gl-accordion-item v-if="policies.length" :title="policiesTitle">
            <div
              v-for="(policy, idx) in policies"
              :key="idx"
              class="gl-m-4 gl-display-flex gl-flex-direction-column gl-align-items-flex-start"
            >
              <gl-link :href="getPolicyEditUrl(policy)">{{ policy.name }}</gl-link>
              <gl-badge
                v-if="policy.source.namespace.fullPath !== groupPath"
                variant="muted"
                size="sm"
              >
                {{ policy.source.namespace.name }}
              </gl-badge>
            </div>
          </gl-accordion-item>
        </gl-accordion>
      </div>
    </template>
  </gl-drawer>
</template>
