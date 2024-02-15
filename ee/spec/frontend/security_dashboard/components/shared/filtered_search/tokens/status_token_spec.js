import { GlFilteredSearchToken } from '@gitlab/ui';
import { nextTick } from 'vue';
import StatusToken from 'ee/security_dashboard/components/shared/filtered_search/tokens/status_token.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Status Token component', () => {
  let wrapper;

  const mockConfig = {
    multiSelect: true,
    unique: true,
    operators: OPERATORS_IS,
  };

  const createWrapper = ({
    value = { data: StatusToken.DEFAULT_VALUES, operator: '=' },
    active = false,
    stubs,
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(StatusToken, {
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
      stubs: {
        QuerystringSync: true,
        ...stubs,
      },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findCheckedIcon = (value) => wrapper.findByTestId(`status-icon-${value}`);
  const isOptionChecked = (v) => !findCheckedIcon(v).classes('gl-visibility-hidden');

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
    const exempt = Array.isArray(value) ? value : [value];

    return StatusToken.GROUPS.flatMap((i) => i.options)
      .map((i) => i.value)
      .filter((i) => !exempt.includes(i));
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
      expect(findSlotView().text()).toBe('Needs triage +1 more');
    });

    it('shows the dropdown with correct options', () => {
      expect(
        findSlotSuggestions()
          .text()
          .split('\n')
          .map((s) => s.trim())
          .filter((i) => i),
      ).toEqual([
        'Status', // subheader
        'All statuses',
        'Needs triage',
        'Confirmed',
        'Resolved',
        'Dismissed as...', // subheader
        'All dismissal reasons',
        'Acceptable risk',
        'False positive',
        'Mitigating control',
        'Used in tests',
        'Not applicable',
      ]);
    });
  });

  describe('item selection', () => {
    beforeEach(async () => {
      createWrapper({});
      await clickDropdownItem('ALL');
    });

    it('toggles the item selection when clicked on', async () => {
      await clickDropdownItem('CONFIRMED', 'RESOLVED');

      expect(isOptionChecked('ALL')).toBe(false);
      expect(isOptionChecked('CONFIRMED')).toBe(true);
      expect(isOptionChecked('RESOLVED')).toBe(true);

      // Add a dismissal reason
      await clickDropdownItem('ACCEPTABLE_RISK');

      expect(isOptionChecked('CONFIRMED')).toBe(true);
      expect(isOptionChecked('RESOLVED')).toBe(true);
      expect(isOptionChecked('ACCEPTABLE_RISK')).toBe(true);
      expect(isOptionChecked('DISMISSED')).toBe(false);

      // Select all
      await clickDropdownItem('ALL');

      allOptionsExcept('ALL').forEach((value) => {
        expect(isOptionChecked(value)).toBe(false);
      });

      // Select All Dismissed Values
      await clickDropdownItem('DISMISSED');

      allOptionsExcept('DISMISSED').forEach((value) => {
        expect(isOptionChecked(value)).toBe(false);
      });

      // Selecting another dismissed should unselect All Dismissed values
      await clickDropdownItem('USED_IN_TESTS');

      expect(isOptionChecked('USED_IN_TESTS')).toBe(true);
      expect(isOptionChecked('DISMISSED')).toBe(false);
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

    it('shows "Dismissed (all reasons)" when only "All dismissal reasons" option is selected', async () => {
      await clickDropdownItem('DISMISSED');
      expect(findSlotView().text()).toBe('Dismissed (all reasons)');
    });

    it('shows "Dismissed (2 reasons)" when only 2 dismissal reasons are selected', async () => {
      await clickDropdownItem('FALSE_POSITIVE', 'ACCEPTABLE_RISK');
      expect(findSlotView().text()).toBe('Dismissed (2 reasons)');
    });

    it('shows "Confirmed +1 more" when confirmed and a dismissal reason are selected', async () => {
      await clickDropdownItem('CONFIRMED', 'FALSE_POSITIVE');
      expect(findSlotView().text()).toBe('Confirmed +1 more');
    });

    it('shows "Confirmed +1 more" when confirmed and all dismissal reasons are selected', async () => {
      await clickDropdownItem('CONFIRMED', 'DISMISSED');
      expect(findSlotView().text()).toBe('Confirmed +1 more');
    });
  });

  describe('QuerystringSync component', () => {
    beforeEach(() => {
      createWrapper({});
    });

    it('has expected props', () => {
      expect(findQuerystringSync().props()).toMatchObject({
        querystringKey: 'state',
        value: StatusToken.DEFAULT_VALUES,
        validValues: [
          'ALL',
          'DETECTED',
          'CONFIRMED',
          'RESOLVED',
          'DISMISSED',
          'ACCEPTABLE_RISK',
          'FALSE_POSITIVE',
          'MITIGATING_CONTROL',
          'USED_IN_TESTS',
          'NOT_APPLICABLE',
        ],
      });
    });

    it('receives ALL_STATUS_VALUE when All Statuses option is clicked', async () => {
      await clickDropdownItem('ALL');

      expect(findQuerystringSync().props('value')).toEqual(['ALL']);
    });

    it.each`
      emitted                      | expected
      ${['CONFIRMED', 'RESOLVED']} | ${['CONFIRMED', 'RESOLVED']}
      ${['ALL']}                   | ${['ALL']}
    `('restores selected items - $emitted', async ({ emitted, expected }) => {
      findQuerystringSync().vm.$emit('input', emitted);
      await nextTick();

      expected.forEach((item) => {
        expect(isOptionChecked(item)).toBe(true);
      });

      allOptionsExcept(expected).forEach((item) => {
        expect(isOptionChecked(item)).toBe(false);
      });
    });
  });
});
