<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { s__ } from '~/locale';

export default {
  BANNER_STORAGE_KEY: 'security_policies_scan_result_name_change',
  i18n: {
    migrationTitle: s__('SecurityOrchestration|Updated policy name'),
    migrationDescription: s__(
      'SecurityOrchestration|The %{oldNameStart}Scan result policy%{oldNameEnd} is now called the %{newNameStart}Merge request approval policy%{newNameEnd} to better align with its purpose.',
    ),
  },
  name: 'ApprovalPolicyNameUpdateBanner',
  components: {
    GlAlert,
    GlSprintf,
    LocalStorageSync,
  },
  data() {
    return {
      alertDismissed: false,
    };
  },
  methods: {
    dismissAlert() {
      this.alertDismissed = true;
    },
  },
};
</script>

<template>
  <local-storage-sync v-model="alertDismissed" :storage-key="$options.BANNER_STORAGE_KEY">
    <gl-alert
      v-if="!alertDismissed"
      :dismissible="true"
      :title="$options.i18n.migrationTitle"
      @dismiss="dismissAlert"
    >
      <gl-sprintf :message="$options.i18n.migrationDescription">
        <template #oldName="{ content }">
          <b>{{ content }}</b>
        </template>
        <template #newName="{ content }">
          <b>{{ content }}</b>
        </template>
      </gl-sprintf>
    </gl-alert>
  </local-storage-sync>
</template>
