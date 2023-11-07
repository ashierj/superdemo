<script>
import Vue from 'vue';
import { GlLoadingIcon, GlTable, GlToast, GlLink, GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import EditForm from 'ee/groups/settings/compliance_frameworks/components/edit_form.vue';
import FrameworkBadge from '../shared/framework_badge.vue';
import FrameworkInfoDrawer from './framework_info_drawer.vue';

Vue.use(GlToast);

export default {
  name: 'FrameworksTable',
  components: {
    GlLoadingIcon,
    GlTable,
    GlLink,
    GlModal,
    EditForm,
    FrameworkInfoDrawer,
    FrameworkBadge,
  },
  props: {
    frameworks: {
      type: Array,
      required: true,
    },
    projects: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selectedFramework: null,
      frameworkSelectedForEdit: null,
    };
  },
  computed: {
    frameworkItems() {
      return this.frameworks.map((framework) => {
        const associatedProjects = this.projects.filter((project) =>
          project.complianceFrameworks.nodes.some((f) => f.id === framework.id),
        );
        return { ...framework, associatedProjects };
      });
    },
    showDrawer() {
      return this.selectedFramework !== null;
    },
  },
  methods: {
    toggleDrawer(item) {
      if (this.selectedFramework?.id === item.id) {
        this.closeDrawer();
      } else {
        this.openDrawer(item);
      }
    },
    openDrawer(item) {
      this.selectedFramework = item;
    },
    closeDrawer() {
      this.selectedFramework = null;
    },
    editComplianceFramework(framework) {
      this.frameworkSelectedForEdit = framework;
      this.$refs.editModal.show();
    },
    resetEditModal() {
      this.frameworkSelectedForEdit = null;
      this.$refs.editModal.hide();
    },
    isLastItem(index, arr) {
      return index >= arr.length - 1;
    },
  },
  fields: [
    {
      key: 'frameworkName',
      label: __('Frameworks'),
      thClass: 'gl-md-max-w-26 gl-vertical-align-middle!',
      tdClass: 'gl-md-max-w-26 gl-vertical-align-middle! gl-cursor-pointer',
      sortable: true,
    },
    {
      key: 'associatedProjects',
      label: __('Associated projects'),
      thClass: 'gl-md-max-w-26 gl-white-space-nowrap gl-vertical-align-middle!',
      tdClass: 'gl-md-max-w-26 gl-vertical-align-middle! gl-cursor-pointer',
      sortable: false,
    },
  ],
  i18n: {
    noFrameworksFound: s__('ComplianceReport|No frameworks found'),
    editTitle: s__('ComplianceFrameworks|Edit compliance framework'),
  },
};
</script>
<template>
  <section>
    <gl-modal
      ref="editModal"
      :title="$options.i18n.editTitle"
      modal-id="edit-framework-form-modal"
      hide-footer
    >
      <edit-form
        v-if="frameworkSelectedForEdit"
        :id="frameworkSelectedForEdit.id"
        :framework="frameworkSelectedForEdit"
        @success="resetEditModal"
        @cancel="resetEditModal"
      />
    </gl-modal>
    <gl-table
      :fields="$options.fields"
      :busy="isLoading"
      :items="frameworkItems"
      no-local-sorting
      show-empty
      stacked="lg"
      hover
      @row-clicked="toggleDrawer"
    >
      <template #cell(frameworkName)="{ item }">
        <framework-badge :framework="item" @edit="editComplianceFramework(item)" />
      </template>
      <template #cell(associatedProjects)="{ item: { associatedProjects } }">
        <div
          v-for="(associatedProject, index) in associatedProjects"
          :key="associatedProject.id"
          class="gl-display-inline-block"
        >
          <gl-link :href="associatedProject.webUrl">{{ associatedProject.name }}</gl-link
          ><span v-if="!isLastItem(index, associatedProjects)">, </span>
        </div>
      </template>
      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="gl-my-5" />
      </template>
      <template #empty>
        <div class="gl-my-5 gl-text-center">
          {{ $options.i18n.noFrameworksFound }}
        </div>
      </template>
    </gl-table>
    <framework-info-drawer
      :show-drawer="showDrawer"
      :framework="selectedFramework"
      @close="closeDrawer"
      @edit="editComplianceFramework"
    />
  </section>
</template>
