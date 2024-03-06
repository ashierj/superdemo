import { shallowMount } from '@vue/test-utils';
import { GlAccordion, GlAccordionItem, GlLink, GlSprintf } from '@gitlab/ui';
import ConfigurationInstructions from 'ee/integrations/edit/components/google_cloud_artifact_registry/configuration_instructions.vue';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';
import { createStore } from '~/integrations/edit/store';
import { mockIntegrationProps } from '../../mock_data';

describe('ConfigurationInstructions', () => {
  let wrapper;

  const findHeader = () => wrapper.find('h3');
  const findDescription = () => wrapper.find('p');
  const findAccordion = () => wrapper.findComponent(GlAccordion);
  const findAccordionItem = () => wrapper.findComponent(GlAccordionItem);
  const findCodeInstruction = () => wrapper.findComponent(CodeInstruction);
  const findLinks = () => wrapper.findAllComponents(GlLink);

  const createComponent = (customState = {}) => {
    const store = createStore({
      customState: { ...mockIntegrationProps, ...customState },
    });

    wrapper = shallowMount(ConfigurationInstructions, {
      store,
      stubs: {
        GlSprintf,
      },
    });
  };

  it('renders header', () => {
    createComponent();

    expect(findHeader().text()).toBe('Configure Google Cloud IAM policies');
  });

  it('renders description', () => {
    createComponent();

    expect(findDescription().text()).toBe(
      'Your Google Cloud project must have specific Identity and Access Management (IAM) policies to use the Artifact Registry repository in this GitLab project.',
    );
  });

  it('renders accordion', () => {
    createComponent();

    expect(findAccordion().props('headerLevel')).toBe(4);
  });

  it('renders collapsed accordion item', () => {
    createComponent();

    expect(findAccordionItem().props('visible')).toBe(false);
  });

  it('passes right props to accordion item', () => {
    createComponent();

    expect(findAccordionItem().props()).toMatchObject({
      title: 'Configuration instructions',
      headerLevel: 3,
    });
  });

  it('renders expanded accordion item when `operating=false`', () => {
    createComponent({ operating: false });

    expect(findAccordionItem().props('visible')).toBe(true);
  });

  it('renders link to Google Cloud CLI installation', () => {
    createComponent();

    expect(findLinks().at(0).attributes()).toMatchObject({
      href: 'https://cloud.google.com/sdk/docs/install',
      target: '_blank',
      rel: 'noopener noreferrer',
    });
  });

  it('renders link to personal access tokens path', () => {
    createComponent();

    expect(findLinks().at(1).attributes()).toMatchObject({
      href: '/path/to/personal/access/tokens',
      target: '_blank',
      rel: 'noopener noreferrer',
    });
  });

  it('renders code instruction with placeholder', () => {
    createComponent();

    expect(findCodeInstruction().props()).toMatchObject({
      copyText: 'Copy command',
      multiline: true,
      instruction: `curl --request GET \\
--header "PRIVATE-TOKEN: <your_access_token>" \\
--data 'google_cloud_artifact_registry_project_id=<your_google_cloud_project_id>' \\
--data 'enable_google_cloud_artifact_registry=true' \\
--url "https://gitlab.com/api/v4/projects/1/google_cloud/setup/integrations.sh" \\
| bash`,
    });
  });
});
