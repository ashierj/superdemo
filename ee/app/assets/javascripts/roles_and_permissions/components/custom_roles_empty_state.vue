<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'CustomRolesEmptyState',
  i18n: {
    emptyStateTitle: s__('MemberRole|Create custom roles'),
    emptyStateDescription: s__(
      'MemberRole|Create a custom role with specific abilities by starting with a base role and adding custom permissions. %{linkStart}Learn more about custom roles.%{linkEnd}',
    ),
    newRoleButton: s__('MemberRole|New role'),
  },
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  inject: ['documentationPath', 'emptyStateSvgPath', 'newRolePath'],
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.emptyStateTitle"
    :svg-path="emptyStateSvgPath"
    :primary-button-link="newRolePath"
    :primary-button-text="$options.i18n.newRoleButton"
  >
    <template #description>
      <gl-sprintf :message="$options.i18n.emptyStateDescription">
        <template #link="{ content }">
          <gl-link :href="documentationPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
