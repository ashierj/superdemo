<script>
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import ListMemberRoles from './list_member_roles.vue';

export default {
  components: {
    GroupSelect,
    ListMemberRoles,
  },
  props: {
    showGroupSelector: {
      type: Boolean,
      required: true,
    },
    groupId: {
      type: String,
      required: false,
      default: '',
    },
    emptyText: {
      type: String,
      required: true,
    },
  },
  data() {
    return { selectedGroupId: this.groupId };
  },
  methods: {
    updateGroup({ value }) {
      this.selectedGroupId = value;
    },
  },
  apiParams: { top_level_only: '1' },
};
</script>

<template>
  <div class="col">
    <group-select
      v-if="showGroupSelector"
      input-id="group-selector"
      input-name="group-selector"
      :api-params="$options.apiParams"
      @input="updateGroup"
    />
    <list-member-roles class="gl-mt-5" :group-id="selectedGroupId" :empty-text="emptyText" />
  </div>
</template>
