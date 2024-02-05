<script>
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { INSTANCE_TYPE } from '~/ci/runner/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import RunnerUsageExportMutation from '../graphql/performance/runner_usage_export.mutation.graphql';

export default {
  name: 'RunnerUsage',
  components: {
    GlButton,
  },
  inject: {
    clickhouseCiAnalyticsAvailable: {
      default: false,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async onClick() {
      const confirmed = await confirmAction(
        s__(
          'Runner|The CSV export contains a list of projects, the number of minutes used by instance runners, and the number of jobs that ran in the previous month. When the export is completed, it is sent as an attachment to your email.',
        ),
        {
          title: s__('Runner|Export runner usage for previous month'),
          primaryBtnText: s__('Runner|Export runner usage'),
        },
      );

      if (!confirmed) {
        return;
      }

      try {
        this.loading = true;

        const {
          data: {
            runnersExportUsage: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: RunnerUsageExportMutation,
          variables: {
            input: {
              type: INSTANCE_TYPE,
            },
          },
        });

        if (errors.length) {
          throw new Error(errors.join(' '));
        }

        this.$toast.show(
          s__(
            'Runner|Your CSV export has started. It will be sent to your email inbox when its ready.',
          ),
        );
      } catch (e) {
        createAlert({
          message: s__(
            'Runner|Something went wrong while generating the CSV export. Please try again.',
          ),
        });
        Sentry.captureException(e);
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>
<template>
  <div v-if="clickhouseCiAnalyticsAvailable" class="gl-border gl-rounded-base gl-p-5">
    <div class="gl-display-flex gl-align-items-center">
      <h2 class="gl-font-lg gl-m-0 gl-flex-grow-1">{{ s__('Runners|Runner Usage') }}</h2>

      <gl-button :loading="loading" size="small" @click="onClick">
        {{ s__('Runners|Export as CSV') }}
      </gl-button>
    </div>
  </div>
</template>
