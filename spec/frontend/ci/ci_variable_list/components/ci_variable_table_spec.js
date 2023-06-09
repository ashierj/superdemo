import { GlAlert, GlBadge, GlKeysetPagination } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CiVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import { EXCEEDS_VARIABLE_LIMIT_TEXT, projectString } from '~/ci/ci_variable_list/constants';
import { mockInheritedVariables, mockVariables } from '../mocks';

describe('Ci variable table', () => {
  let wrapper;

  const defaultProps = {
    entity: 'project',
    isLoading: false,
    maxVariableLimit: mockVariables(projectString).length + 1,
    pageInfo: {},
    variables: mockVariables(projectString),
  };

  const mockMaxVariableLimit = defaultProps.variables.length;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = mountExtended(CiVariableTable, {
      attachTo: document.body,
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures: {
          ciVariablesPages: false,
        },
        isInheritedGroupVars: false,
        ...provide,
      },
    });
  };

  const findRevealButton = () => wrapper.findByText('Reveal values');
  const findAddButton = () => wrapper.findByLabelText('Add');
  const findEditButton = () => wrapper.findByLabelText('Edit');
  const findEmptyVariablesPlaceholder = () => wrapper.findByText('There are no variables yet.');
  const findHiddenValues = () => wrapper.findAllByTestId('hiddenValue');
  const findLimitReachedAlerts = () => wrapper.findAllComponents(GlAlert);
  const findRevealedValues = () => wrapper.findAllByTestId('revealedValue');
  const findAttributesRow = (rowIndex) =>
    wrapper.findAllByTestId('ci-variable-table-row-attributes').at(rowIndex);
  const findAttributeByIndex = (rowIndex, attributeIndex) =>
    findAttributesRow(rowIndex).findAllComponents(GlBadge).at(attributeIndex).text();
  const findTableColumnText = (index) => wrapper.findAll('th').at(index).text();
  const findGroupCiCdSettingsLink = (rowIndex) =>
    wrapper.findAllByTestId('ci-variable-table-row-cicd-path').at(rowIndex).attributes('href');
  const findKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);

  const generateExceedsVariableLimitText = (entity, currentVariableCount, maxVariableLimit) => {
    return sprintf(EXCEEDS_VARIABLE_LIMIT_TEXT, { entity, currentVariableCount, maxVariableLimit });
  };

  describe.each`
    isVariablePagesEnabled | text
    ${true}                | ${'enabled'}
    ${false}               | ${'disabled'}
  `('When Pages FF is $text', ({ isVariablePagesEnabled }) => {
    const provide = isVariablePagesEnabled ? { glFeatures: { ciVariablesPages: true } } : {};

    describe('When table is empty', () => {
      beforeEach(() => {
        createComponent({ props: { variables: [] }, provide });
      });

      it('displays empty message', () => {
        expect(findEmptyVariablesPlaceholder().exists()).toBe(true);
      });

      it('hides the reveal button', () => {
        expect(findRevealButton().exists()).toBe(false);
      });
    });

    describe('When table has CI variables', () => {
      beforeEach(() => {
        createComponent({ provide });
      });

      // last column is for the edit button, which has no text
      it.each`
        index | text
        ${0}  | ${'Key (Click to sort descending)'}
        ${1}  | ${'Value'}
        ${2}  | ${'Attributes'}
        ${3}  | ${'Environments'}
        ${4}  | ${''}
      `('renders the $text column', ({ index, text }) => {
        expect(findTableColumnText(index)).toEqual(text);
      });

      it('does not display the empty message', () => {
        expect(findEmptyVariablesPlaceholder().exists()).toBe(false);
      });

      it('displays the correct amount of variables', () => {
        expect(wrapper.findAll('.js-ci-variable-row')).toHaveLength(defaultProps.variables.length);
      });

      it.each`
        rowIndex | attributeIndex | text
        ${0}     | ${0}           | ${'Protected'}
        ${0}     | ${1}           | ${'Expanded'}
        ${1}     | ${0}           | ${'File'}
        ${1}     | ${1}           | ${'Masked'}
      `(
        'displays variable attribute $text for row $rowIndex',
        ({ rowIndex, attributeIndex, text }) => {
          expect(findAttributeByIndex(rowIndex, attributeIndex)).toBe(text);
        },
      );

      it('renders action buttons', () => {
        expect(findRevealButton().exists()).toBe(true);
        expect(findAddButton().exists()).toBe(true);
        expect(findEditButton().exists()).toBe(true);
      });

      it('enables the Add Variable button', () => {
        expect(findAddButton().props('disabled')).toBe(false);
      });
    });

    describe('When table has inherited CI variables', () => {
      beforeEach(() => {
        createComponent({
          props: { variables: mockInheritedVariables },
          provide: { isInheritedGroupVars: true, ...provide },
        });
      });

      it.each`
        index | text
        ${0}  | ${'Key'}
        ${1}  | ${'Attributes'}
        ${2}  | ${'Environments'}
        ${3}  | ${'Group'}
      `('renders the $text column', ({ index, text }) => {
        expect(findTableColumnText(index)).toEqual(text);
      });

      it('does not render action buttons', () => {
        expect(findRevealButton().exists()).toBe(false);
        expect(findAddButton().exists()).toBe(false);
        expect(findEditButton().exists()).toBe(false);
        expect(findKeysetPagination().exists()).toBe(false);
      });

      it('displays the correct amount of variables', () => {
        expect(wrapper.findAll('.js-ci-variable-row')).toHaveLength(mockInheritedVariables.length);
      });

      it.each`
        rowIndex | attributeIndex | text
        ${0}     | ${0}           | ${'Protected'}
        ${0}     | ${1}           | ${'Masked'}
        ${0}     | ${2}           | ${'Expanded'}
        ${2}     | ${0}           | ${'File'}
        ${2}     | ${1}           | ${'Protected'}
      `(
        'displays variable attribute $text for row $rowIndex',
        ({ rowIndex, attributeIndex, text }) => {
          expect(findAttributeByIndex(rowIndex, attributeIndex)).toBe(text);
        },
      );

      it('displays link to the group settings', () => {
        expect(findGroupCiCdSettingsLink(0)).toBe(mockInheritedVariables[0].groupCiCdSettingsPath);
        expect(findGroupCiCdSettingsLink(1)).toBe(mockInheritedVariables[1].groupCiCdSettingsPath);
      });
    });

    describe('When variables have exceeded the max limit', () => {
      beforeEach(() => {
        createComponent({
          props: { maxVariableLimit: mockVariables(projectString).length },
          provide,
        });
      });

      it('disables the Add Variable button', () => {
        expect(findAddButton().props('disabled')).toBe(true);
      });
    });

    describe('max limit reached alert', () => {
      describe('when there is no variable limit', () => {
        beforeEach(() => {
          createComponent({
            props: { maxVariableLimit: 0 },
            provide,
          });
        });

        it('hides alert', () => {
          expect(findLimitReachedAlerts().length).toBe(0);
        });
      });

      describe('when variable limit exists', () => {
        it('hides alert when limit has not been reached', () => {
          createComponent({ provide });

          expect(findLimitReachedAlerts().length).toBe(0);
        });

        it('shows alert when limit has been reached', () => {
          const exceedsVariableLimitText = generateExceedsVariableLimitText(
            defaultProps.entity,
            defaultProps.variables.length,
            mockMaxVariableLimit,
          );

          createComponent({
            props: { maxVariableLimit: mockMaxVariableLimit },
          });

          expect(findLimitReachedAlerts().length).toBe(2);

          expect(findLimitReachedAlerts().at(0).props('dismissible')).toBe(false);
          expect(findLimitReachedAlerts().at(0).text()).toContain(exceedsVariableLimitText);

          expect(findLimitReachedAlerts().at(1).props('dismissible')).toBe(false);
          expect(findLimitReachedAlerts().at(1).text()).toContain(exceedsVariableLimitText);
        });
      });
    });

    describe('Table click actions', () => {
      beforeEach(() => {
        createComponent({ provide });
      });

      it('reveals secret values when button is clicked', async () => {
        expect(findHiddenValues()).toHaveLength(defaultProps.variables.length);
        expect(findRevealedValues()).toHaveLength(0);

        await findRevealButton().trigger('click');

        expect(findHiddenValues()).toHaveLength(0);
        expect(findRevealedValues()).toHaveLength(defaultProps.variables.length);
      });

      it('dispatches `setSelectedVariable` with correct variable to edit', async () => {
        await findEditButton().trigger('click');

        expect(wrapper.emitted('set-selected-variable')).toEqual([[defaultProps.variables[0]]]);
      });

      it('dispatches `setSelectedVariable` with no variable when adding a new one', async () => {
        await findAddButton().trigger('click');

        expect(wrapper.emitted('set-selected-variable')).toEqual([[null]]);
      });
    });
  });
});
