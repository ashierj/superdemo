<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { STATE_GUIDED } from './constants';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    InviteMembersTrigger,
  },
  STATE_GUIDED,
};
</script>

<template>
  <div>
    <h3>{{ s__('GoogleCloud|Manual setup') }}</h3>
    <p>
      <gl-sprintf
        :message="
          s__(
            'GoogleCloud|%{linkStart}Switch to the guided setup%{linkEnd} if you can manage workload identity federation in Google Cloud. %{link2Start}What are the required permissions?%{link2End}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link @click="$emit('show', $options.STATE_GUIDED)">{{ content }}</gl-link>
        </template>
        >
        <template #link2="{ content }">
          <gl-link
            href="https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#required-roles"
            target="_blank"
          >
            {{ content }}
            <gl-icon name="external-link" :aria-label="__('(external link)')" />
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <h4>{{ s__('GoogleCloud|Instructions') }}</h4>
    <ol>
      <li>
        <gl-sprintf
          :message="
            s__(
              'GoogleCloud|Share the following information with someone that can manage Google Cloud workload identity federation. Or %{linkStart}invite them%{linkEnd} to set up.',
            )
          "
        >
          <template #link="{ content }">
            <invite-members-trigger
              :display-text="content"
              class="gl-vertical-align-baseline"
              variant="link"
              trigger-source="google_cloud_artifact_registry_setup"
            />
          </template>
          >
        </gl-sprintf>
      </li>
      <ol type="a">
        <li>
          {{ s__('GoogleCloud|The setup instructions page') }}
        </li>
        <li>
          {{ s__('GoogleCloud|Your GitLab project ID') }}
        </li>
        <li>
          {{ s__('GoogleCloud|Your workload identify federation (WLIF) issuer URL.') }}
        </li>
      </ol>
      <li>
        {{
          s__(
            'GoogleCloud|After the Google Cloud workload identity federation has been set up, complete the following fields.',
          )
        }}
      </li>
    </ol>
    <hr class="gl-border-gray-100" />
  </div>
</template>
