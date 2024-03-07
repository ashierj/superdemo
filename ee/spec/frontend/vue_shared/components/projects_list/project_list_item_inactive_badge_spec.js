import { GlBadge } from '@gitlab/ui';
import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ProjectListItemInactiveBadge from 'ee/vue_shared/components/projects_list/project_list_item_inactive_badge.vue';

describe('ProjectListItemInactiveBadgeEE', () => {
  let wrapper;

  const [project] = convertObjectPropsToCamelCase(projects, { deep: true });

  const defaultProps = {
    project,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ProjectListItemInactiveBadge, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);

  describe.each`
    archived | markedForDeletionOn | variant      | text
    ${false} | ${null}             | ${false}     | ${false}
    ${true}  | ${null}             | ${'info'}    | ${'Archived'}
    ${false} | ${'2024-01-01'}     | ${'warning'} | ${'Pending deletion'}
    ${true}  | ${'2024-01-01'}     | ${'warning'} | ${'Pending deletion'}
  `(
    'when project.archived is $archived and project.markedForDeletionOn is $markedForDeletionOn',
    ({ archived, markedForDeletionOn, variant, text }) => {
      beforeEach(() => {
        createComponent({
          props: {
            project: {
              ...project,
              archived,
              markedForDeletionOn,
            },
          },
        });
      });

      it('renders the badge correctly', () => {
        expect(findGlBadge().exists() && findGlBadge().props('variant')).toBe(variant);
        expect(findGlBadge().exists() && findGlBadge().text()).toBe(text);
      });
    },
  );
});
