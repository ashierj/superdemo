<script>
import { GlSprintf, GlLink, GlButton, GlModalDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { usageQuotasHelpPaths } from '~/usage_quotas/storage/constants';
import { getSubscriptionPermissionsData } from 'ee/fulfillment/shared_queries/subscription_actions_reason.customer.query.graphql';
import { LIMITED_ACCESS_KEYS } from 'ee/usage_quotas/components/constants';
import {
  BUY_STORAGE,
  STORAGE_INCLUDED_IN_PLAN_PROJECT_ENFORCEMENT,
  STORAGE_INCLUDED_IN_PLAN_NAMESPACE_ENFORCEMENT,
  NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
  PROJECT_ENFORCEMENT_TYPE_SUBTITLE,
  NAMESPACE_ENFORCEMENT_TYPE_SUBTITLE,
} from '../constants';
import LimitedAccessModal from '../../components/limited_access_modal.vue';
import StorageStatisticsCard from './storage_statistics_card.vue';
import TotalStorageAvailableBreakdownCard from './total_storage_available_breakdown_card.vue';
import ExcessStorageBreakdownCard from './excess_storage_breakdown_card.vue';

export default {
  components: {
    GlSprintf,
    GlLink,
    GlButton,
    LimitedAccessModal,
    StorageStatisticsCard,
    TotalStorageAvailableBreakdownCard,
    ExcessStorageBreakdownCard,
  },
  directives: {
    GlModalDirective,
  },
  inject: [
    'purchaseStorageUrl',
    'buyAddonTargetAttr',
    'namespacePlanName',
    'isUsingProjectEnforcement',
    'namespacePlanStorageIncluded',
    'namespaceId',
  ],
  apollo: {
    // handling loading state is not needed in the first iteration of https://gitlab.com/gitlab-org/gitlab/-/issues/409750
    subscriptionPermissions: {
      query: getSubscriptionPermissionsData,
      client: 'customersDotClient',
      variables() {
        return {
          namespaceId: parseInt(this.namespaceId, 10),
        };
      },
      skip() {
        return !gon.features?.limitedAccessModal;
      },
      update: (data) => ({
        ...data.subscription,
        reason: data.userActionAccess?.limitedAccessReason,
      }),
    },
  },
  props: {
    additionalPurchasedStorageSize: {
      type: Number,
      required: false,
      default: null,
    },
    usedStorage: {
      type: Number,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      subscriptionPermissions: {},
      isLimitedAccessModalShown: false,
    };
  },
  i18n: {
    purchaseButtonText: BUY_STORAGE,
    namespaceStorageOverviewSubtitle: NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
  },
  computed: {
    enforcementTypei18n() {
      return this.isUsingProjectEnforcement
        ? {
            title: sprintf(STORAGE_INCLUDED_IN_PLAN_PROJECT_ENFORCEMENT, {
              planName: this.namespacePlanName,
            }),
            subtitle: sprintf(PROJECT_ENFORCEMENT_TYPE_SUBTITLE, {
              planLimit: numberToHumanSize(this.includedStorage, 1),
            }),
            learnMoreUrl: usageQuotasHelpPaths.usageQuotasProjectStorageLimit,
          }
        : {
            title: sprintf(STORAGE_INCLUDED_IN_PLAN_NAMESPACE_ENFORCEMENT, {
              planName: this.namespacePlanName,
            }),
            subtitle: sprintf(NAMESPACE_ENFORCEMENT_TYPE_SUBTITLE, {
              planLimit: numberToHumanSize(this.includedStorage, 1),
            }),
            learnMoreUrl: usageQuotasHelpPaths.usageQuotasNamespaceStorageLimit,
          };
    },
    includedStorage() {
      return Number(this.namespacePlanStorageIncluded || 0);
    },
    purchasedStorage() {
      return Number(this.additionalPurchasedStorageSize || 0);
    },
    totalStorage() {
      return (
        Number(this.namespacePlanStorageIncluded || 0) +
        Number(this.additionalPurchasedStorageSize || 0)
      );
    },
    shouldShowLimitedAccessModal() {
      // NOTE: we're using existing flag for seats `canAddSeats`, to infer
      // whether the storage is expandable.
      const canAddStorage = this.subscriptionPermissions?.canAddSeats ?? true;

      return (
        !canAddStorage &&
        gon.features?.limitedAccessModal &&
        LIMITED_ACCESS_KEYS.includes(this.subscriptionPermissions.reason)
      );
    },
  },
  methods: {
    showLimitedAccessModal() {
      this.isLimitedAccessModalShown = true;
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <h3 data-testid="overview-subtitle">{{ $options.i18n.namespaceStorageOverviewSubtitle }}</h3>
      <template v-if="purchaseStorageUrl && !isUsingProjectEnforcement">
        <gl-button
          v-if="!shouldShowLimitedAccessModal"
          :href="purchaseStorageUrl"
          :target="buyAddonTargetAttr"
          category="primary"
          variant="confirm"
          data-testid="purchase-more-storage"
        >
          {{ $options.i18n.purchaseButtonText }}
        </gl-button>

        <gl-button
          v-else
          v-gl-modal-directive="'limited-access-modal-id'"
          category="primary"
          variant="confirm"
          data-testid="purchase-more-storage"
          @click="showLimitedAccessModal"
        >
          {{ $options.i18n.purchaseButtonText }}
        </gl-button>
      </template>
    </div>
    <p class="gl-mb-0">
      <gl-sprintf :message="enforcementTypei18n.subtitle">
        <template #link="{ content }">
          <gl-link :href="enforcementTypei18n.learnMoreUrl">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <div class="gl-display-flex gl-sm-flex-direction-column gl-gap-5 gl-py-4">
      <storage-statistics-card
        :plan-storage-description="enforcementTypei18n.title"
        :used-storage="usedStorage"
        :total-storage="totalStorage"
        :loading="loading"
        data-testid="namespace-usage-total"
        class="gl-w-full"
      />
      <template v-if="namespacePlanName">
        <excess-storage-breakdown-card
          v-if="isUsingProjectEnforcement"
          :purchased-storage="purchasedStorage"
          :limited-access-mode-enabled="shouldShowLimitedAccessModal"
          :loading="loading"
        />
        <total-storage-available-breakdown-card
          v-else
          :plan-storage-description="enforcementTypei18n.title"
          :included-storage="includedStorage"
          :purchased-storage="purchasedStorage"
          :total-storage="totalStorage"
          :loading="loading"
        />
      </template>
    </div>
    <limited-access-modal
      v-if="shouldShowLimitedAccessModal"
      v-model="isLimitedAccessModalShown"
      :limited-access-reason="subscriptionPermissions.reason"
    />
  </div>
</template>
