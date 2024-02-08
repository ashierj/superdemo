<script>
import { GlAvatar, GlButton, GlLink, GlTableLite } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, formatNumber } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { INSTANCE_TYPE } from '~/ci/runner/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import RunnerUsageQuery from '../graphql/performance/runner_usage.query.graphql';
import RunnerUsageByProjectQuery from '../graphql/performance/runner_usage_by_project.query.graphql';
import RunnerUsageExportMutation from '../graphql/performance/runner_usage_export.mutation.graphql';

const thClass = ['gl-font-sm!', 'gl-text-secondary!'];

export default {
  name: 'RunnerUsage',
  components: {
    GlAvatar,
    GlButton,
    GlLink,
    GlTableLite,
  },
  data() {
    return {
      loading: false,
    };
  },
  apollo: {
    topProjects: {
      query: RunnerUsageByProjectQuery,
      update(data) {
        return data.runnerUsageByProject;
      },
    },
    topRunners: {
      query: RunnerUsageQuery,
      update(data) {
        return data.runnerUsage;
      },
    },
  },
  methods: {
    formatNumber,
    runnerName(runner) {
      const { id: graphqlId, shortSha, description } = runner;
      const id = getIdFromGraphQLId(graphqlId);

      if (description) {
        return `#${id} (${shortSha}) - ${description}`;
      }
      return `#${id} (${shortSha})`;
    },
    findClosestTd(el) {
      return el.closest('td');
    },
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
  topRunnersFields: [
    {
      key: 'runner',
      label: s__('Runners|Most used instance runners'),
      thClass: [...thClass, 'gl-width-full'],
    },
    {
      key: 'ciMinutesUsed',
      label: s__('Runners|Usage (min)'),
      thClass: [...thClass, 'gl-text-right'],
      tdClass: 'gl-text-right',
    },
  ],
  topProjectsFields: [
    {
      key: 'project',
      label: s__('Runners|Top projects consuming runners'),
      thClass: [...thClass, 'gl-width-full'],
    },
    {
      key: 'ciMinutesUsed',
      label: s__('Runners|Usage (min)'),
      thClass: [...thClass, 'gl-text-right'],
      tdClass: 'gl-text-right',
    },
  ],
};
</script>
<template>
  <div class="gl-border gl-rounded-base gl-p-5">
    <div class="gl-display-flex gl-align-items-center gl-mb-4">
      <h2 class="gl-font-lg gl-flex-grow-1 gl-m-0">
        {{ s__('Runners|Runner Usage (previous month)') }}
      </h2>
      <gl-button :loading="loading" size="small" @click="onClick">
        {{ s__('Runners|Export as CSV') }}
      </gl-button>
    </div>

    <div
      class="gl-md-display-flex gl-justify-content-space-between gl-align-items-flex-start gl-gap-4"
    >
      <gl-table-lite
        :fields="$options.topProjectsFields"
        :items="topProjects"
        class="runners-top-result-table runners-dashboard-half-gap-4"
        data-testid="top-projects-table"
      >
        <template #cell(project)="{ value }">
          <template v-if="value">
            <gl-avatar
              :label="value.name"
              :src="value.avatarUrl"
              shape="rect"
              :size="16"
              :entity-name="value.name"
            />
            <gl-link :href="value.webUrl" class="gl-text-body!"> {{ value.name }} </gl-link>
          </template>
          <template v-else> {{ s__('Runners|Other projects') }} </template>
        </template>

        <template #cell(ciMinutesUsed)="{ value }">{{ formatNumber(value) }}</template>
      </gl-table-lite>

      <gl-table-lite
        :fields="$options.topRunnersFields"
        :items="topRunners"
        class="runners-top-result-table runners-dashboard-half-gap-4"
        data-testid="top-runners-table"
      >
        <template #cell(runner)="{ value }">
          <gl-link v-if="value" :href="value.adminUrl" class="gl-text-body!">
            {{ runnerName(value) }}
          </gl-link>
          <template v-else> {{ s__('Runners|Other runners') }} </template>
        </template>
        <template #cell(ciMinutesUsed)="{ value }">{{ formatNumber(value) }}</template>
      </gl-table-lite>
    </div>
  </div>
</template>
