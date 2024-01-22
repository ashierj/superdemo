import { GlAlert, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ArtifactRegistryListHeader from 'ee_component/packages_and_registries/google_artifact_registry/components/list/header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { headerData } from '../../mock_data';

describe('Google Artifact Registry list page header', () => {
  let wrapper;

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findRepositoryNameSubHeader = () => wrapper.findByTestId('repository-name');
  const findProjectIDSubHeader = () => wrapper.findByTestId('project-id');
  const findOpenInGoogleCloudLink = () => wrapper.findComponent(GlButton);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const defaultProps = { data: headerData };

  const createComponent = (propsData = defaultProps) => {
    wrapper = shallowMountExtended(ArtifactRegistryListHeader, {
      stubs: {
        TitleArea,
      },
      propsData,
    });
  };

  describe('header', () => {
    it('has a title', () => {
      createComponent({ data: {}, isLoading: true });

      expect(findTitleArea().props()).toMatchObject({
        title: 'Google Artifact Registry',
        metadataLoading: true,
      });
      expect(findAlert().exists()).toBe(false);
    });

    it('has external link to google cloud', () => {
      createComponent();

      expect(findOpenInGoogleCloudLink().text()).toBe('Open in Google Cloud');
      expect(findOpenInGoogleCloudLink().attributes('href')).toBe(
        defaultProps.data.gcpRepositoryUrl,
      );
    });

    describe('sub header parts', () => {
      describe('repository name', () => {
        it('exists', () => {
          createComponent();

          expect(findRepositoryNameSubHeader().props()).toMatchObject({
            text: defaultProps.data.repository,
            textTooltip: 'Repository name',
            icon: 'folder',
            size: 'xl',
          });
        });
      });

      describe('project id', () => {
        it('exists', () => {
          createComponent();

          expect(findProjectIDSubHeader().props()).toMatchObject({
            text: defaultProps.data.project,
            textTooltip: 'Project ID',
            icon: 'project',
            size: 'xl',
          });
        });
      });
    });

    describe('has error', () => {
      it('shows alert', () => {
        createComponent({ showError: true });

        expect(findAlert().text()).toBe('An error occurred while fetching the artifacts.');
        expect(findRepositoryNameSubHeader().exists()).toBe(false);
        expect(findProjectIDSubHeader().exists()).toBe(false);
        expect(findOpenInGoogleCloudLink().exists()).toBe(false);
      });
    });
  });
});
