import { shallowMount } from '@vue/test-utils';
import App from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';
import DastProfileSummaryCard from 'ee/security_configuration/dast_profiles/dast_profile_selector/dast_profile_summary_card.vue';
import { scannerProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

const [profile] = scannerProfiles;

describe('DastScannerProfileSummary', () => {
  let wrapper;

  const createWrapper = (options = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        profile,
      },
      stubs: {
        DastProfileSummaryCard,
      },
      ...options,
    });
  };

  it('renders properly', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when on-demand browser based scans feature flag is enabled', () => {
    it('does not show AJAX Spider summary line', () => {
      createWrapper({
        provide: { glFeatures: { dastOdsBrowserBasedScanner: true } },
      });

      expect(wrapper.find('[data-testid="summary-cell-ajax-spider"]').exists()).toBe(false);
    });
  });

  describe('when on-demand browser based scans feature flag is disabled', () => {
    it('does show AJAX Spider summary line', () => {
      createWrapper({
        provide: { glFeatures: { dastOdsBrowserBasedScanner: false } },
      });
      expect(wrapper.find('[data-testid="summary-cell-ajax-spider"]').exists()).toBe(true);
    });
  });
});
