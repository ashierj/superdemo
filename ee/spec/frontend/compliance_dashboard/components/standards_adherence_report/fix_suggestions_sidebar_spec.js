import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FixSuggestionsSidebar from 'ee/compliance_dashboard/components/standards_adherence_report/fix_suggestions_sidebar.vue';

describe('FixSuggestionsSidebar component', () => {
  let wrapper;

  const findRequirementSectionTitle = () => wrapper.findByTestId('sidebar-requirement-title');
  const findRequirementSectionContent = () => wrapper.findByTestId('sidebar-requirement-content');
  const findFailureSectionReasonTitle = () => wrapper.findByTestId('sidebar-failure-title');
  const findFailureSectionReasonContent = () => wrapper.findByTestId('sidebar-failure-content');
  const findHowToFixSection = () => wrapper.findByTestId('sidebar-how-to-fix');
  const findManageRulesBtn = () => wrapper.findByTestId('sidebar-mr-settings-button');
  const findLearnMoreBtn = () => wrapper.findByTestId('sidebar-mr-settings-learn-more-button');

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(FixSuggestionsSidebar, {
      propsData: {
        showDrawer: true,
        groupPath: 'example-group',
        ...propsData,
      },
    });
  };

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          adherence: {
            checkName: '',
            status: 'PASS',
            project: {
              id: 'gid://gitlab/Project/21',
              name: 'example project',
            },
          },
        },
      });
    });

    describe('for drawer body content', () => {
      it('renders the `requirement` title', () => {
        expect(findRequirementSectionTitle().text()).toBe('Requirement');
      });

      it('renders the `failure reason` title', () => {
        expect(findFailureSectionReasonTitle().text()).toBe('Failure reason');
      });

      it('renders the `how to fix` title and description', () => {
        expect(findHowToFixSection().text()).toContain('How to fix');
        expect(findHowToFixSection().text()).toContain(
          'The following features help satisfy this requirement',
        );
      });
    });
  });

  describe('content for each check type', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          adherence: {
            checkName: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR',
            status: 'PASS',
            project: {
              id: 'gid://gitlab/Project/21',
              name: 'example project',
              webUrl: 'example.com/groups/example-group/example-project',
            },
          },
        },
      });
    });

    describe('for checks related to MRs', () => {
      describe('for the `how to fix` section', () => {
        it('has the details', () => {
          expect(findHowToFixSection().text()).toContain('Merge request approval rules');

          expect(findHowToFixSection().text()).toContain(
            "Update approval settings in the project's merge request settings to satisfy this requirement.",
          );
        });

        it('has the `manage rules` button', () => {
          expect(findManageRulesBtn().text()).toBe('Manage rules');

          expect(findManageRulesBtn().attributes('href')).toBe(
            'example.com/groups/example-group/example-project/-/settings/merge_requests',
          );
        });

        it('has the `learn more` button', () => {
          expect(findLearnMoreBtn().text()).toBe('Learn more');

          expect(findLearnMoreBtn().attributes('href')).toBe(
            '/help/user/project/merge_requests/approvals/rules',
          );
        });
      });

      describe.each`
        checkName                                         | expectedRequirement                                                                    | expectedFailureReason
        ${'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR'}     | ${'Have a valid rule that prevents author approved merge requests'}                    | ${'No rule is configured to prevent author approved merge requests.'}
        ${'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS'} | ${'Have a valid rule that prevents merge requests approved by committers'}             | ${'No rule configured to prevent merge requests approved by committers.'}
        ${'AT_LEAST_TWO_APPROVALS'}                       | ${'Have a valid rule that requires any merge request to have more than two approvals'} | ${'No rule is configured to require two approvals.'}
      `('when check is $checkName', ({ checkName, expectedRequirement, expectedFailureReason }) => {
        beforeEach(() => {
          createComponent({
            propsData: {
              adherence: {
                checkName,
                status: 'PASS',
                project: {
                  id: 'gid://gitlab/Project/21',
                  name: 'example project',
                },
              },
            },
          });
        });

        it('renders the requirement', () => {
          expect(findRequirementSectionContent().text()).toBe(expectedRequirement);
        });

        it('renders the failure reason', () => {
          expect(findFailureSectionReasonContent().text()).toBe(expectedFailureReason);
        });
      });
    });
  });
});
