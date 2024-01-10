import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { CreateAgent } from 'ee/ml/ai_agents/apps';

initSimpleApp('#js-mount-new-ml-agent', CreateAgent, { withApolloProvider: true });
