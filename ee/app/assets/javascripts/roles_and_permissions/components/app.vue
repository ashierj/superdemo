<script>
import { GlLoadingIcon, GlSprintf, GlLink, GlButton, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, n__, sprintf } from '~/locale';
import groupMemberRolesQuery from 'ee/invite_members/graphql/queries/group_member_roles.query.graphql';
import instanceMemberRolesQuery from '../graphql/instance_member_roles.query.graphql';
import CustomRolesEmptyState from './custom_roles_empty_state.vue';
import CustomRolesTable from './custom_roles_table.vue';

export default {
  name: 'CustomRolesApp',
  i18n: {
    title: s__('MemberRole|Custom roles'),
    description: s__(
      'MemberRole|You can create a custom role by adding specific %{linkStart}permissions to a base role.%{linkEnd}',
    ),
    createRoleText: s__('MemberRole|Create new role'),
    fetchRolesError: s__('MemberRole|Failed to fetch roles.'),
  },
  components: {
    GlLoadingIcon,
    GlSprintf,
    GlLink,
    GlButton,
    GlIcon,
    CustomRolesEmptyState,
    CustomRolesTable,
  },
  inject: ['documentationPath', 'groupFullPath'],
  data() {
    return {
      customRoles: [],
    };
  },
  apollo: {
    customRoles: {
      query() {
        return this.fetchMemberRolesQuery;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        const nodes = this.groupFullPath
          ? data?.namespace?.memberRoles?.nodes
          : data?.memberRoles?.nodes;

        return nodes || [];
      },
      error() {
        createAlert({
          message: this.$options.i18n.fetchRolesError,
        });
      },
    },
  },
  computed: {
    fetchMemberRolesQuery() {
      return this.groupFullPath ? groupMemberRolesQuery : instanceMemberRolesQuery;
    },
    queryVariables() {
      return this.groupFullPath ? { fullPath: this.groupFullPath } : {};
    },
    isLoading() {
      return this.$apollo.queries.customRoles.loading;
    },
    customRolesCount() {
      return sprintf(
        n__('%{count} Custom role', '%{count} Custom roles', this.customRoles.length),
        {
          count: this.customRoles.length,
        },
      );
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-5" />

  <custom-roles-empty-state v-else-if="!customRoles.length" />

  <section v-else>
    <header>
      <div
        class="gl-display-flex gl-align-items-flex-start gl-flex-wrap page-title gl-mb-2 gl-gap-2"
      >
        <h1 class="gl-font-size-h-display gl-m-0 gl-mr-auto gl-white-space-nowrap">
          {{ $options.i18n.title }}
        </h1>
        <gl-button variant="confirm">
          {{ $options.i18n.createRoleText }}
        </gl-button>
      </div>

      <p class="gl-mb-7">
        <gl-sprintf :message="$options.i18n.description">
          <template #link="{ content }">
            <gl-link :href="documentationPath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </header>

    <div class="gl-font-weight-bold gl-mb-4" data-testid="custom-roles-count">
      <gl-icon name="shield" class="gl-mr-2" />
      <span>{{ customRolesCount }}</span>
    </div>

    <custom-roles-table :custom-roles="customRoles" />
  </section>
</template>
