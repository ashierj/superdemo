<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { s__ } from '~/locale';

export default {
  MATCH_ON_INCLUSION_PATH: helpPagePath('user/application_security/policies/scan-result-policies', {
    anchor: 'license_finding-rule-type',
  }),
  SCAN_FINDING_TYPE_PATH: helpPagePath('user/application_security/policies/scan-result-policies', {
    anchor: 'scan_finding-rule-type',
  }),
  BANNER_STORAGE_KEY: 'security_policies_breaking_changes',
  i18n: {
    bannerTitle: s__('SecurityOrchestration|Merge result policy syntax changes'),
    bannerDescription: s__(
      'SecurityOrchestration|Several merge result policy criteria have been deprecated. Policies using these elements will not work after GitLab 17.0 (May 10, 2024). You must edit these policies to remove the deprecated criteria.',
    ),
    bannerSubheader: s__('SecurityOrchestration|Summary of syntax changes:'),
    matchOnInclusionChange: s__(
      'SecurityOrchestration|match_on_inclusion is replaced by %{linkStart}match_on_inclusion_license%{linkEnd}',
    ),
    newlyDeprecatedChange: s__(
      'SecurityOrchestration|newly_deprecated is replaced by %{firstLinkStart}New::Needs Triage%{firstLinkEnd} and %{secondLinkStart}New::Dismissed%{secondLinkEnd}',
    ),
    graphqlChange: s__(
      'SecurityOrchestration|project.networkpolicies will be removed (GraphQL API associated with the network policies)',
    ),
  },
  name: 'BreakingChangesBanner',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    LocalStorageSync,
  },
  data() {
    return {
      alertDismissed: false,
    };
  },
  mounted() {
    this.emitChange();
  },
  methods: {
    dismissAlert() {
      this.alertDismissed = true;
      this.emitChange();
    },
    emitChange() {
      this.$emit('dismiss', this.alertDismissed);
    },
  },
};
</script>

<template>
  <local-storage-sync v-model="alertDismissed" :storage-key="$options.BANNER_STORAGE_KEY">
    <gl-alert
      v-if="!alertDismissed"
      :title="$options.i18n.bannerTitle"
      :dismissible="true"
      @dismiss="dismissAlert"
    >
      <p>{{ $options.i18n.bannerDescription }}</p>
      <p>{{ $options.i18n.bannerSubheader }}</p>

      <ul class="gl-mb-0">
        <li>
          <gl-sprintf :message="$options.i18n.matchOnInclusionChange">
            <template #link="{ content }">
              <gl-link :href="$options.MATCH_ON_INCLUSION_PATH" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </li>
        <li>
          <gl-sprintf :message="$options.i18n.newlyDeprecatedChange">
            <template #firstLink="{ content }">
              <gl-link :href="$options.SCAN_FINDING_TYPE_PATH" target="_blank">{{
                content
              }}</gl-link>
            </template>
            <template #secondLink="{ content }">
              <gl-link :href="$options.SCAN_FINDING_TYPE_PATH" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </li>
        <li>
          {{ $options.i18n.graphqlChange }}
        </li>
      </ul>
    </gl-alert>
  </local-storage-sync>
</template>
