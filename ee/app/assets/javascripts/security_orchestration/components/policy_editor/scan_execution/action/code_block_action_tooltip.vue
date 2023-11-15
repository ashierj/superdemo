<script>
import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  SCAN_EXECUTION_PATH: helpPagePath('user/application_security/policies/scan-execution-policies', {
    anchor: 'scan-action-type',
  }),
  i18n: {
    customSectionPopoverTitle: __('Information'),
    customSectionPopoverContent: s__(
      'ScanExecutionPolicy|If there are any conflicting variables with the local pipeline configuration (Ex, gitlab-ci.yml) then variables defined here will take precedence. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  name: 'CodeBlockActionTooltip',
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
      target="code-block-action-icon"
      show-close-button
      :title="$options.i18n.customSectionPopoverTitle"
    >
      <gl-sprintf :message="$options.i18n.customSectionPopoverContent">
        <template #link="{ content }">
          <gl-link class="gl-font-sm" target="_blank" :href="$options.SCAN_EXECUTION_PATH">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-popover>

    <gl-icon id="code-block-action-icon" class="gl-text-blue-600" name="question-o" />
  </div>
</template>
