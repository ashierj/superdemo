<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { STEPS } from 'ee/subscriptions/constants';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';
import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
import { s__, sprintf } from '~/locale';
import Api from 'ee/api';
import { trackTransaction } from '~/google_tag_manager';
import Tracking from '~/tracking';
import { addExperimentContext } from '~/tracking/utils';
import { ActiveModelError } from '~/lib/utils/error_utils';
import { isInvalidPromoCodeError } from 'ee/subscriptions/new/utils';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  data() {
    return {
      isActive: {},
      isConfirmingOrder: false,
    };
  },
  apollo: {
    isActive: {
      query: activeStepQuery,
      update: ({ activeStep }) => activeStep?.id === STEPS[3].id,
      error: (error) => this.handleError(error),
    },
  },
  computed: {
    ...mapGetters([
      'hasValidPriceDetails',
      'confirmOrderParams',
      'totalExVat',
      'vat',
      'selectedPlanDetails',
    ]),
    shouldDisableConfirmOrder() {
      return this.isConfirmingOrder || !this.hasValidPriceDetails;
    },
  },
  methods: {
    handleError(error) {
      this.$emit(PurchaseEvent.ERROR, error);
    },
    trackConfirmOrder(message) {
      Tracking.event(
        'default',
        'click_button',
        addExperimentContext({ label: 'confirm_purchase', property: message }),
      );
    },
    shouldShowErrorMessageOnly(errors) {
      if (!errors?.message) {
        return false;
      }

      return isInvalidPromoCodeError(errors);
    },
    confirmOrder() {
      this.isConfirmingOrder = true;

      Api.confirmOrder(this.confirmOrderParams)
        .then(({ data }) => {
          if (data?.location) {
            const transactionDetails = {
              paymentOption: this.confirmOrderParams?.subscription?.payment_method_id,
              revenue: this.totalExVat,
              tax: this.vat,
              selectedPlan: this.selectedPlanDetails?.value,
              quantity: this.confirmOrderParams?.subscription?.quantity,
            };

            trackTransaction(transactionDetails);
            this.trackConfirmOrder(s__('Checkout|Success: subscription'));

            visitUrl(data.location);
          } else {
            let errorMessage;
            if (data?.name) {
              errorMessage = sprintf(
                s__('Checkout|Name: %{errorMessage}'),
                { errorMessage: data.name.join(', ') },
                false,
              );
            } else if (this.shouldShowErrorMessageOnly(data?.errors)) {
              errorMessage = data?.errors?.message;
            } else {
              errorMessage = data?.errors;
            }

            this.trackConfirmOrder(errorMessage);
            this.handleError(
              new ActiveModelError(data.error_attribute_map, JSON.stringify(errorMessage)),
            );
          }
        })
        .catch((error) => {
          this.trackConfirmOrder(error.message);
          this.handleError(error);
        })
        .finally(() => {
          this.isConfirmingOrder = false;
        });
    },
  },
  i18n: {
    confirm: s__('Checkout|Confirm purchase'),
    confirming: s__('Checkout|Confirming...'),
  },
};
</script>
<template>
  <div v-if="isActive" class="full-width gl-mt-5 gl-mb-7">
    <gl-button
      :disabled="shouldDisableConfirmOrder"
      variant="confirm"
      category="primary"
      @click="confirmOrder"
    >
      <gl-loading-icon v-if="isConfirmingOrder" inline size="sm" />
      {{ isConfirmingOrder ? $options.i18n.confirming : $options.i18n.confirm }}
    </gl-button>
  </div>
</template>
