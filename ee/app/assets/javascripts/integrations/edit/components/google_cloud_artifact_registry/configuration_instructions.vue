<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { GlAccordion, GlAccordionItem, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

export default {
  components: {
    CodeInstruction,
    GlAccordion,
    GlAccordionItem,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapGetters(['propsSource']),
    operating() {
      return this.propsSource.operating;
    },
    projectId() {
      return this.propsSource.projectId;
    },
    personalAccessTokensPath() {
      return this.propsSource.personalAccessTokensPath;
    },
    instructions() {
      return `curl --request GET \\
--header "PRIVATE-TOKEN: <your_access_token>" \\
--data 'google_cloud_artifact_registry_project_id=<your_google_cloud_project_id>' \\
--data 'enable_google_cloud_artifact_registry=true' \\
--url "https://gitlab.com/api/v4/projects/${this.projectId}/google_cloud/setup/integrations.sh" \\
| bash`;
    },
  },
};
</script>

<template>
  <div>
    <h3>
      {{ s__('GoogleArtifactRegistry|Configure Google Cloud IAM policies') }}
    </h3>
    <p>
      {{
        s__(
          'GoogleArtifactRegistry|Your Google Cloud project must have specific Identity and Access Management (IAM) policies to use the Artifact Registry repository in this GitLab project.',
        )
      }}
    </p>
    <gl-accordion :header-level="4" class="gl-mb-5">
      <gl-accordion-item
        :title="s__('GoogleArtifactRegistry|Configuration instructions')"
        :header-level="3"
        :visible="!operating"
      >
        <p>
          <gl-sprintf
            :message="
              s__(
                'GoogleArtifactRegistry|Before you begin, %{linkStart}install the Google Cloud CLI%{linkEnd}.',
              )
            "
          >
            <template #link="{ content }">
              <gl-link
                href="https://cloud.google.com/sdk/docs/install"
                target="_blank"
                rel="noopener noreferrer"
                >{{ content }} <gl-icon name="external-link" :aria-label="__('(external link)')"
              /></gl-link>
            </template>
          </gl-sprintf>
        </p>
        <p>
          {{
            s__(
              'GoogleArtifactRegistry|Run the following command to setup IAM read and write policies in your Google Cloud project.',
            )
          }}
        </p>
        <ul>
          <li>
            <gl-sprintf
              :message="
                s__(
                  'GoogleArtifactRegistry|Replace %{codeStart}your_access_token%{codeEnd} with a new %{linkStart}personal access token%{linkEnd} with the %{strongStart}read_api%{strongEnd} scope. This token gets information from your Google Cloud IAM integration in GitLab.',
                )
              "
              ><template #code="{ content }">
                <code>&lt;{{ content }}&gt;</code>
              </template>
              <template #strong="{ content }">
                <strong>{{ content }}</strong>
              </template>
              <template #link="{ content }">
                <gl-link
                  :href="personalAccessTokensPath"
                  target="_blank"
                  rel="noopener noreferrer"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf
              :message="
                s__(
                  'GoogleArtifactRegistry|Replace %{codeStart}your_google_cloud_project_id%{codeEnd} with your Google Cloud project ID.',
                )
              "
              ><template #code="{ content }">
                <code>&lt;{{ content }}&gt;</code>
              </template>
            </gl-sprintf>
          </li>
          <li>
            {{ s__('GoogleArtifactRegistry|You might be prompted to sign into Google.') }}
          </li>
        </ul>
        <code-instruction
          :instruction="instructions"
          :copy-text="s__('GoogleArtifactRegistry|Copy command')"
          multiline
        />
        <gl-sprintf
          :message="
            s__(
              'GoogleArtifactRegistry|After the policies have been created, select %{strongStart}Save changes%{strongEnd} to continue.',
            )
          "
          ><template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
