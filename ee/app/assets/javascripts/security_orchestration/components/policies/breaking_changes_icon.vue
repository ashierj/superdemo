<script>
import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  BREAKING_CHANGES_PATH: helpPagePath('user/application_security/policies/scan-result-policies', {
    anchor: 'merge-request-approval-policy-schema',
  }),
  i18n: {
    description: s__(
      "SecurityOrchestration|This policy won't work after GitLab 17.0 (May 16, 2024). You must edit the policy and replace the deprecated syntax%{deprecatedProperties}. For details on which syntax has been deprecated, see %{linkStart}Documentation%{linkEnd}.",
    ),
    title: s__('SecurityOrchestration|Policy contains deprecated syntax'),
  },
  name: 'BreakingChangesIcon',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
  },
  props: {
    id: {
      type: String,
      required: false,
      default: '',
    },
    deprecatedProperties: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    popoverDescription() {
      const hasDeprecatedProperties = this.deprecatedProperties.length > 0;
      const deprecatedProperties = this.deprecatedProperties.join(', ');

      return sprintf(this.$options.i18n.description, {
        deprecatedProperties: hasDeprecatedProperties ? ` (${deprecatedProperties})` : '',
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-popover :title="$options.i18n.title" :target="id" show-close-button>
      <gl-sprintf :message="popoverDescription">
        <template #link="{ content }">
          <gl-link :href="$options.BREAKING_CHANGES_PATH" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-popover>
    <gl-icon :id="id" class="gl-text-orange-600" name="warning" />
  </div>
</template>
