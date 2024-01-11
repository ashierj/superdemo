import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { ShowAgent } from 'ee/ml/ai_agents/apps';

initSimpleApp('#js-mount-show-ml-agent', ShowAgent, { withApolloProvider: true });
