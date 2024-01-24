<script>
import {
  GlButton,
  GlCard,
  GlTableLite,
  GlSprintf,
  GlLink,
  GlBadge,
  GlLabel,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { LONG_DATE_FORMAT_WITH_TZ } from '~/vue_shared/constants';
import { NEW_ROUTE_NAME, DETAILS_ROUTE_NAME } from '../../constants';

export default {
  name: 'SecretsTable',
  components: {
    GlButton,
    GlCard,
    GlTableLite,
    GlSprintf,
    GlLink,
    GlBadge,
    GlLabel,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    TimeAgo,
    UserDate,
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
  },
  fields: [
    {
      key: 'name',
      label: s__('Secrets|Secret name'),
    },
    {
      key: 'lastAccessed',
      label: s__('Secrets|Last accessed'),
    },
    {
      key: 'createdOn',
      label: s__('Secrets|Created on'),
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-py-3! gl-px-0!',
    },
  ],
  createdOnFormat: LONG_DATE_FORMAT_WITH_TZ,
  NEW_ROUTE_NAME,
};
</script>
<template>
  <div>
    <h1>{{ s__('Secrets|Secrets') }}</h1>
    <p>
      <gl-sprintf
        :message="
          s__(
            'Secrets|Secrets represent sensitive information your CI job needs to complete work. This sensitive information can be items like API tokens, database credentials, or private keys. Unlike CI/CD variables, which are always presented to a job, secrets must be explicitly required by a job. %{linkStart}Learn more.%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link href="#" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <gl-card body-class="gl-p-0">
      <template #header>
        <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
          <strong>
            {{ s__('Secrets|Stored secrets') }}
            <gl-badge size="sm" class="gl-ml-3" data-testid="secrets-count">
              {{ secretsCount }}
            </gl-badge>
          </strong>
          <gl-button size="small" :to="$options.NEW_ROUTE_NAME" data-testid="new-secret-button">
            {{ s__('Secrets|New secret') }}
          </gl-button>
        </div>
      </template>
      <gl-table-lite :fields="$options.fields" :items="secrets">
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
            :key="label.title"
            :title="label.title"
            :background-color="label.color"
            :scoped="label.title.includes('::')"
            size="sm"
            class="gl-mt-3 gl-mr-3"
          />
        </template>
        <template #cell(lastAccessed)="{ item: { lastAccessed } }">
          <time-ago :time="lastAccessed" data-testid="secret-last-accessed" />
        </template>
        <template #cell(createdOn)="{ item: { createdOn } }">
          <user-date
            :date="createdOn"
            :date-format="$options.createdOnFormat"
            data-testid="secret-created-on"
          />
        </template>
        <template #cell(actions)="{ item: { key } }">
          <gl-disclosure-dropdown
            icon="ellipsis_v"
            toggle-text="Actions"
            text-sr-only
            category="tertiary"
            no-caret
            data-testid="secret-actions"
          >
            <gl-disclosure-dropdown-item>
              <template #list-item>
                <router-link
                  data-testid="secret-details-link"
                  :to="getDetailsRoute(key)"
                  class="gl-display-block gl-text-body gl-hover-text-gray-900 gl-hover-text-decoration-none"
                >
                  {{ s__('Secrets|Edit secret') }}
                </router-link>
              </template>
            </gl-disclosure-dropdown-item>
            <gl-disclosure-dropdown-item>
              <template #list-item>
                {{ s__('Secrets|Delete') }}
              </template>
            </gl-disclosure-dropdown-item>
            <gl-disclosure-dropdown-item>
              <template #list-item>
                {{ s__('Secrets|Revoke') }}
              </template>
            </gl-disclosure-dropdown-item>
          </gl-disclosure-dropdown>
        </template>
      </gl-table-lite>
    </gl-card>
  </div>
</template>
