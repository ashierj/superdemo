<script>
import { GlButton, GlTabs, GlTab } from '@gitlab/ui';
import { EDIT_ROUTE_NAME, DETAILS_ROUTE_NAME, AUDIT_LOG_ROUTE_NAME } from '../constants';

export default {
  name: 'SecretTabs',
  components: {
    GlButton,
    GlTabs,
    GlTab,
  },
  computed: {
    tabIndex() {
      return this.$route.name === AUDIT_LOG_ROUTE_NAME ? 1 : 0;
    },
  },
  methods: {
    goTo(name) {
      if (this.$route.name !== name) {
        this.$router.push({ name });
      }
    },
  },
  EDIT_ROUTE_NAME,
  DETAILS_ROUTE_NAME,
  AUDIT_LOG_ROUTE_NAME,
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-mt-4">
      <h1>{{ $route.params.key }}</h1>

      <router-link data-testid="edit-secret-link" :to="{ name: $options.EDIT_ROUTE_NAME }">
        <gl-button icon="pencil" :aria-label="__('Edit')" />
      </router-link>
    </div>

    <gl-tabs :value="tabIndex">
      <gl-tab @click="goTo($options.DETAILS_ROUTE_NAME)">
        <template #title>{{ s__('Secrets|Secret details') }}</template>
      </gl-tab>
      <gl-tab @click="goTo($options.AUDIT_LOG_ROUTE_NAME)">
        <template #title>{{ s__('Secrets|Audit log') }}</template>
      </gl-tab>

      <router-view />
    </gl-tabs>
  </div>
</template>
