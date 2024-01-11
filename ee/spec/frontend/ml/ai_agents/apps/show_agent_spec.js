import { GlExperimentBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { ShowAgent } from 'ee/ml/ai_agents/apps';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

let wrapper;

const createWrapper = () => {
  wrapper = shallowMount(ShowAgent, {
    propsData: { projectPath: 'path/to/project', agentId: '2' },
  });
};

const findTitleArea = () => wrapper.findComponent(TitleArea);
const findBadge = () => wrapper.findComponent(GlExperimentBadge);

describe('ee/ml/ai_agents/apps/create_agent', () => {
  beforeEach(() => createWrapper());

  it('shows the title', () => {
    expect(findTitleArea().text()).toContain('AI Agent: 2');
  });

  it('displays the experiment badge', () => {
    expect(findBadge().exists()).toBe(true);
  });
});
