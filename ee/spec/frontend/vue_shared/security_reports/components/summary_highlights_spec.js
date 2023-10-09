import { GlSprintf } from '@gitlab/ui';
import SummaryHighlights from 'ee/vue_shared/security_reports/components/summary_highlights.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('MR Widget Security Reports - Summary Highlights', () => {
  let wrapper;

  const createComponent = ({ highlights } = {}) => {
    wrapper = shallowMountExtended(SummaryHighlights, {
      propsData: {
        highlights,
      },
      stubs: { GlSprintf },
    });
  };

  it('should display the summary highlights properly', () => {
    createComponent({
      highlights: {
        critical: 10,
        high: 20,
        other: 60,
      },
    });

    expect(wrapper.html()).toMatchSnapshot();
  });

  it("calculate 'others' when other severities are provided", () => {
    const others = { medium: 50, low: 30, unknown: 20 };

    createComponent({
      highlights: {
        critical: 10,
        high: 20,
        ...others,
      },
    });

    expect(wrapper.text()).toContain('100 others');
  });
});
