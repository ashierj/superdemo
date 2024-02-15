import { GlExperimentBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ShowAgent from 'ee/ml/ai_agents/views/show_agent.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

let wrapper;

const createWrapper = () => {
  wrapper = shallowMountExtended(ShowAgent, {
    provide: { projectPath: 'path/to/project' },
    mocks: {
      $route: {
        params: {
          agentId: 2,
        },
      },
    },
  });
};

const findTitleArea = () => wrapper.findComponent(TitleArea);
const findBadge = () => wrapper.findComponent(GlExperimentBadge);

describe('ee/ml/ai_agents/views/create_agent', () => {
  beforeEach(() => createWrapper());

  it('shows the title', () => {
    expect(findTitleArea().text()).toContain('AI Agent: 2');
  });

  it('displays the experiment badge', () => {
    expect(findBadge().exists()).toBe(true);
  });
});
