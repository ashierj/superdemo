import { GlBadge, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ListAgents } from 'ee/ml/ai_agents/apps';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

let wrapper;

const createWrapper = () => {
  wrapper = shallowMountExtended(ListAgents, { propsData: { projectPath: 'path/to/project' } });
};

const findTitleArea = () => wrapper.findComponent(TitleArea);
const findCreateButton = () => findTitleArea().findComponent(GlButton);
const findBadge = () => wrapper.findComponent(GlBadge);

describe('ee/ml/model_registry/apps/list_agents', () => {
  beforeEach(() => createWrapper());

  it('shows the title', () => {
    expect(findTitleArea().text()).toContain('AI Agents');
  });

  it('displays the experiment badge', () => {
    expect(findBadge().attributes().href).toBe('/help/policy/experiment-beta-support#experiment');
  });

  it('shows create agent button', () => {
    expect(findCreateButton().exists()).toBe(true);
  });
});
