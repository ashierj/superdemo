import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ApprovalRules from 'ee/merge_requests/components/reviewers/approval_rules.vue';

describe('Reviewer drawer approval rules component', () => {
  let wrapper;

  const findOptionalToggle = () => wrapper.findByTestId('optional-rules-toggle');
  const findRuleRows = () => wrapper.findAll('tbody tr');

  function createComponent() {
    wrapper = mountExtended(ApprovalRules, {
      propsData: {
        group: {
          label: 'Rule',
          rules: [
            {
              approvalsRequired: 0,
              name: 'Optional rule',
              approvedBy: {
                nodes: [],
              },
            },
            {
              approvalsRequired: 1,
              name: 'Required rule',
              approvedBy: {
                nodes: [],
              },
            },
            {
              approvalsRequired: 1,
              name: 'Approved rule',
              approvedBy: {
                nodes: [{ id: 1 }],
              },
            },
          ],
        },
      },
    });
  }

  it('renders optional rules toggle button', () => {
    createComponent();

    expect(findOptionalToggle().exists()).toBe(true);
    expect(findOptionalToggle().text()).toBe('1 optional rule.');
  });

  it('renders non-optional rules by default', () => {
    createComponent();

    const row = findRuleRows().at(0);

    expect(row.element).toMatchSnapshot();
  });

  it('renders approved by count', () => {
    createComponent();

    const row = findRuleRows().at(1);

    expect(row.text()).toContain('1 of 1');
  });

  it('toggles optional rows when clicking toggle', async () => {
    createComponent();

    findOptionalToggle().vm.$emit('click');

    await nextTick();

    expect(findRuleRows().length).toBe(3);
    expect(findRuleRows().at(2).element).toMatchSnapshot();
  });
});
