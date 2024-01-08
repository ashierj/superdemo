import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { ListAgents } from 'ee/ml/ai_agents/apps';

initSimpleApp('#js-mount-index-ml-agents', ListAgents, { withApolloProvider: true });
