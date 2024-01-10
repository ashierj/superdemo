import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ValueStreamFeedbackBanner from 'ee/analytics/dashboards/components/value_stream_feedback_banner.vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { DASHBOARD_SURVEY_LINK } from 'ee/analytics/dashboards/constants';

describe('Value Stream Feedback Banner', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const createWrapper = (shouldShowCallout = true) => {
    userCalloutDismissSpy = jest.fn();
    wrapper = shallowMountExtended(ValueStreamFeedbackBanner, {
      stubs: {
        GlSprintf,
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAlertText = () => findAlert().findComponent(GlSprintf).text();
  const findLink = () => wrapper.findComponent(GlLink);

  it('displays the alert banner correctly', () => {
    createWrapper();

    expect(findAlertText()).toBe(
      'To help us improve the Value Stream Management Dashboard, please share feedback about your experience in this',
    );

    expect(findLink().text()).toBe('survey');
    expect(findLink().attributes('href')).toBe(DASHBOARD_SURVEY_LINK);
  });

  it('dismisses the callout when closed', () => {
    createWrapper();

    findAlert().vm.$emit('dismiss');

    expect(userCalloutDismissSpy).toHaveBeenCalled();
  });

  it('is not displayed once it has been dismissed', () => {
    createWrapper(false);

    expect(findAlert().exists()).toBe(false);
  });
});
