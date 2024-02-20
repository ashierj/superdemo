<script>
import { GlButton, GlCard, GlTableLite, GlSprintf, GlLabel } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { LONG_DATE_FORMAT_WITH_TZ } from '~/vue_shared/constants';
import {
  NEW_ROUTE_NAME,
  DETAILS_ROUTE_NAME,
  EDIT_ROUTE_NAME,
  SCOPED_LABEL_COLOR,
  UNSCOPED_LABEL_COLOR,
} from '../../constants';
import SecretActionsCell from './secret_actions_cell.vue';

export default {
  name: 'SecretsTable',
  components: {
    GlButton,
    GlCard,
    GlTableLite,
    GlSprintf,
    GlLabel,
    TimeAgo,
    UserDate,
    SecretActionsCell,
  },
  props: {
    secrets: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    secretsCount() {
      return this.secrets.length;
    },
  },
  methods: {
    getDetailsRoute: (key) => ({ name: DETAILS_ROUTE_NAME, params: { key } }),
    getEditRoute: (key) => ({ name: EDIT_ROUTE_NAME, params: { key } }),
    isScopedLabel(label) {
      return label.includes('::');
    },
    getLabelBackgroundColor(label) {
      return this.isScopedLabel(label) ? SCOPED_LABEL_COLOR : UNSCOPED_LABEL_COLOR;
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('Secrets|Name'),
    },
    {
      key: 'lastAccessed',
      label: s__('Secrets|Last accessed'),
    },
    {
      key: 'createdAt',
      label: s__('Secrets|Created'),
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-py-3! gl-px-0!',
    },
  ],
  LONG_DATE_FORMAT_WITH_TZ,
  NEW_ROUTE_NAME,
};
</script>
<template>
  <div>
    <h1 class="page-title gl-font-size-h-display">{{ s__('Secrets|Secrets') }}</h1>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Secrets|Secrets represent sensitive information your CI job needs to complete work. This sensitive information can be items like API tokens, database credentials, or private keys. Unlike CI/CD variables, which are always presented to a job, secrets must be explicitly required by a job.',
          )
        "
      />
    </p>

    <gl-card
      class="gl-new-card"
      header-class="gl-new-card-header"
      body-class="gl-new-card-body gl-px-0"
    >
      <template #header>
        <div class="gl-new-card-title-wrapper">
          <h3 class="gl-new-card-title">
            {{ s__('Secrets|Stored secrets') }}
            <span class="gl-new-card-count" data-testid="secrets-count">{{ secretsCount }}</span>
          </h3>
        </div>
        <div class="gl-new-card-actions">
          <gl-button size="small" :to="$options.NEW_ROUTE_NAME" data-testid="new-secret-button">
            {{ s__('Secrets|New secret') }}
          </gl-button>
        </div>
      </template>
      <gl-table-lite :fields="$options.fields" :items="secrets" stacked="md" class="gl-mb-0">
        <template #cell(name)="{ item: { key, name, labels } }">
          <router-link
            data-testid="secret-details-link"
            :to="getDetailsRoute(key)"
            class="gl-display-block"
          >
            {{ name }}
          </router-link>
          <gl-label
            v-for="label in labels"
            :key="label"
            :title="label"
            :background-color="getLabelBackgroundColor(label)"
            :scoped="isScopedLabel(label)"
            size="sm"
            class="gl-mt-3 gl-mr-3"
          />
        </template>
        <template #cell(lastAccessed)="{ item: { lastAccessed } }">
          <time-ago :time="lastAccessed" data-testid="secret-last-accessed" />
        </template>
        <template #cell(createdAt)="{ item: { createdAt } }">
          <user-date
            :date="createdAt"
            :date-format="$options.LONG_DATE_FORMAT_WITH_TZ"
            data-testid="secret-created-at"
          />
        </template>
        <template #cell(actions)="{ item: { key } }">
          <secret-actions-cell :details-route="getEditRoute(key)" />
        </template>
      </gl-table-lite>
    </gl-card>
  </div>
</template>
