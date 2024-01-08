<script>
import { GlBadge } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MEMBER_ROLE } from '~/graphql_shared/constants';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import enabledMemberRolePermissions from '../../graphql/queries/enabled_member_role_permissions.query.graphql';

export default {
  components: {
    GlBadge,
  },
  props: {
    memberRoleId: {
      type: Number,
      required: true,
    },
    customPermissions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      enabledPermissions: [],
      permissions: this.customPermissions,
    };
  },
  watch: {
    memberRoleId(newMemberRoleId) {
      this.$apollo.addSmartQuery('enabledPermissions', {
        query: enabledMemberRolePermissions,
        variables: () => ({
          id: convertToGraphQLId(TYPENAME_MEMBER_ROLE, newMemberRoleId),
        }),
        update: (data) => data.memberRole.enabledPermissions,
        result: () => {
          this.permissions = this.enabledPermissions.nodes;
        },
        error: (error) => {
          Sentry.captureException(error);
        },
      });
    },
  },
  i18n: {
    title: s__('MemberRole|Custom permissions:'),
  },
};
</script>

<template>
  <div
    class="gl-mt-3 gl-display-flex gl-flex-wrap gl-justify-content-end gl-lg-justify-content-start gl-gap-2"
  >
    <span data-testid="title">{{ $options.i18n.title }}</span>
    <gl-badge v-for="permission in permissions" :key="permission.name" variant="success" size="sm">
      {{ permission.name }}
    </gl-badge>
  </div>
</template>
