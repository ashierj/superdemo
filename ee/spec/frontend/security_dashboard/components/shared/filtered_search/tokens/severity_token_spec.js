import { GlFilteredSearchToken } from '@gitlab/ui';
import { nextTick } from 'vue';
import SeverityToken from 'ee/security_dashboard/components/shared/filtered_search/tokens/severity_token.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Severity Token component', () => {
  let wrapper;

  const mockConfig = {
    multiSelect: true,
    unique: true,
    operators: OPERATORS_IS,
  };

  const createWrapper = ({
    value = {},
    active = false,
    stubs,
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(SeverityToken, {
      propsData: {
        config: mockConfig,
        value,
        active,
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: jest.fn(),
        termsAsTokens: () => false,
      },

      stubs,
    });
  };

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findCheckedIcon = (value) => wrapper.findByTestId(`severity-icon-${value}`);

  const clickDropdownItem = async (...ids) => {
    await Promise.all(
      ids.map((id) => {
        findFilteredSearchToken().vm.$emit('select', id);
        return nextTick();
      }),
    );

    await nextTick();
  };

  const allOptionsExcept = (value) => {
    return SeverityToken.items.map((i) => i.value).filter((i) => i !== value);
  };

  describe('default view', () => {
    const findSlotView = () => wrapper.findByTestId('slot-view');
    const findSlotSuggestions = () => wrapper.findByTestId('slot-suggestions');

    beforeEach(() => {
      createWrapper({
        stubs: {
          GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
            template: `
            <div>
                <div data-testid="slot-view">
                    <slot name="view"></slot>
                </div>
                <div data-testid="slot-suggestions">
                    <slot name="suggestions"></slot>
                </div>
            </div>`,
          }),
        },
      });
    });

    it('shows the label', () => {
      expect(findSlotView().text()).toBe('All severities');
    });

    it('shows the dropdown with correct options', () => {
      expect(
        findSlotSuggestions()
          .text()
          .split('\n')
          .map((s) => s.trim())
          .filter((i) => i),
      ).toEqual(['All severities', 'Critical', 'High', 'Medium', 'Low', 'Info', 'Unknown']);
    });
  });

  describe('item selection', () => {
    beforeEach(async () => {
      createWrapper({});
      await clickDropdownItem('ALL');
    });

    it('toggles the item selection when clicked on', async () => {
      const isOptionChecked = (v) => !findCheckedIcon(v).classes('gl-visibility-hidden');

      await clickDropdownItem('CRITICAL', 'HIGH');

      expect(isOptionChecked('ALL')).toBe(false);
      expect(isOptionChecked('CRITICAL')).toBe(true);
      expect(isOptionChecked('HIGH')).toBe(true);

      // Select All items
      await clickDropdownItem('ALL');

      allOptionsExcept('ALL').forEach((value) => {
        expect(isOptionChecked(value)).toBe(false);
      });

      // Select low
      await clickDropdownItem('LOW');

      expect(isOptionChecked('LOW')).toBe(true);
      allOptionsExcept('LOW').forEach((value) => {
        expect(isOptionChecked(value)).toBe(false);
      });

      // Unselecting low should select all items once again
      await clickDropdownItem('LOW');

      expect(isOptionChecked('ALL')).toBe(true);
      allOptionsExcept('ALL').forEach((value) => {
        expect(isOptionChecked(value)).toBe(false);
      });
    });
  });

  describe('toggle text', () => {
    const findSlotView = () => wrapper.findAllByTestId('filtered-search-token-segment').at(2);

    beforeEach(async () => {
      createWrapper({ value: {}, mountFn: mountExtended });

      // Let's set initial state as ALL. It's easier to manipulate because
      // selecting a new value should unselect this value automatically and
      // we can start from an empty state.
      await clickDropdownItem('ALL');
    });

    it('shows "All severities" when "All severities" option is selected', async () => {
      await clickDropdownItem('ALL');
      expect(findSlotView().text()).toBe('All severities');
    });

    it('shows "Critical +1 more" when critical and high severities are selected', async () => {
      await clickDropdownItem('CRITICAL', 'HIGH');
      expect(findSlotView().text()).toBe('Critical +1 more');
    });

    it('shows "Low" when only low severity is selected', async () => {
      await clickDropdownItem('LOW');
      expect(findSlotView().text()).toBe('Low');
    });
  });
});
