<script>
import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  COMPLIANCE_FRAMEWORK_PATH: helpPagePath('user/group/compliance_frameworks.md'),
  i18n: {
    complianceFrameworkPopoverTitle: __('Information'),
    complianceFrameworkPopoverContent: s__(
      'SecurityOrchestration|A compliance framework is a label to identify that your project has certain compliance requirements. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  name: 'ComplianceFrameworkTooltip',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
  },
};
</script>

<template>
  <div>
    <gl-popover
      target="compliance-framework-icon"
      show-close-button
      :title="$options.i18n.complianceFrameworkPopoverTitle"
    >
      <gl-sprintf :message="$options.i18n.complianceFrameworkPopoverContent">
        <template #link="{ content }">
          <gl-link class="gl-font-sm" target="_blank" :href="$options.COMPLIANCE_FRAMEWORK_PATH">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-popover>

    <gl-icon id="compliance-framework-icon" class="gl-text-blue-600" name="question-o" />
  </div>
</template>
