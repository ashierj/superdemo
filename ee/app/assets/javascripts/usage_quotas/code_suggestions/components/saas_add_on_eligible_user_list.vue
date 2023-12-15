<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { fetchPolicies } from '~/lib/graphql';
import getAddOnEligibleUsers from 'ee/usage_quotas/add_on/graphql/saas_add_on_eligible_users.query.graphql';
import {
  ADD_ON_ELIGIBLE_USERS_FETCH_ERROR_CODE,
  ADD_ON_ERROR_DICTIONARY,
} from 'ee/usage_quotas/error_constants';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';
import AddOnEligibleUserList from 'ee/usage_quotas/code_suggestions/components/add_on_eligible_user_list.vue';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';

const PER_PAGE = 20;

export default {
  name: 'SaasAddOnEligibleUserList',
  components: {
    ErrorAlert,
    AddOnEligibleUserList,
  },
  inject: ['fullPath'],
  props: {
    addOnPurchaseId: {
      type: String,
      required: true,
    },
  },
  addOnErrorDictionary: ADD_ON_ERROR_DICTIONARY,
  data() {
    return {
      addOnEligibleUsers: undefined,
      addOnEligibleUsersFetchError: undefined,
      pageInfo: undefined,
      pageSize: PER_PAGE,
      pagination: {
        first: PER_PAGE,
        last: null,
        after: null,
        before: null,
      },
      filterOptions: {},
    };
  },
  apollo: {
    addOnEligibleUsers: {
      query: getAddOnEligibleUsers,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      variables() {
        return this.queryVariables;
      },
      update({ namespace }) {
        this.pageInfo = namespace?.addOnEligibleUsers?.pageInfo;
        return namespace?.addOnEligibleUsers?.nodes;
      },
      error(error) {
        this.handleAddOnUsersFetchError(error);
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.fullPath,
        addOnType: ADD_ON_CODE_SUGGESTIONS,
        addOnPurchaseIds: [this.addOnPurchaseId],
        ...this.filterOptions,
        ...this.pagination,
      };
    },
  },
  methods: {
    clearAddOnEligibleUsersFetchError() {
      this.addOnEligibleUsersFetchError = undefined;
    },
    handleAddOnUsersFetchError(error) {
      this.addOnEligibleUsersFetchError = ADD_ON_ELIGIBLE_USERS_FETCH_ERROR_CODE;
      Sentry.captureException(error);
    },
    handleNext(endCursor) {
      this.pagination = {
        first: this.pageSize,
        last: null,
        before: null,
        after: endCursor,
      };
    },
    handlePrev(startCursor) {
      this.pagination = {
        first: null,
        last: this.pageSize,
        before: startCursor,
        after: null,
      };
    },
    handleFilter(filterOptions) {
      this.pagination = {
        first: this.pageSize,
        last: null,
        after: null,
        before: null,
      };
      this.filterOptions = filterOptions;
    },
  },
};
</script>

<template>
  <add-on-eligible-user-list
    :add-on-purchase-id="addOnPurchaseId"
    :users="addOnEligibleUsers"
    :is-loading="$apollo.loading"
    :page-info="pageInfo"
    @next="handleNext"
    @prev="handlePrev"
    @filter="handleFilter"
  >
    <template #error-alert>
      <error-alert
        v-if="addOnEligibleUsersFetchError"
        data-testid="add-on-eligible-users-fetch-error"
        :error="addOnEligibleUsersFetchError"
        :error-dictionary="$options.addOnErrorDictionary"
        :dismissible="true"
        @dismiss="clearAddOnEligibleUsersFetchError"
      />
    </template>
  </add-on-eligible-user-list>
</template>
