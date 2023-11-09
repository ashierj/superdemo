<script>
import { GlButton, GlCard, GlTableLite, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NEW_ROUTE_NAME, DETAILS_ROUTE_NAME } from '../../constants';

export default {
  name: 'SecretsTable',
  components: {
    GlButton,
    GlCard,
    GlTableLite,
    GlSprintf,
    GlLink,
  },
  props: {
    secrets: {
      type: Array,
      required: false,
      default: () => [],
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
  ],
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
        <strong>
          {{ s__('Secrets|Stored secrets') }}
        </strong>
        <router-link data-testid="new-secret-link" :to="{ name: $options.NEW_ROUTE_NAME }">
          <gl-button size="small" class="gl-float-right">
            {{ s__('Secrets|New secret') }}
          </gl-button>
        </router-link>
      </template>
      <gl-table-lite :fields="$options.fields" :items="secrets">
        <template #cell(name)="{ item: { key } }">
          <router-link data-testid="secret-details-link" :to="getDetailsRoute(key)">
            {{ key }}
          </router-link>
        </template>
      </gl-table-lite>
    </gl-card>
  </div>
</template>
