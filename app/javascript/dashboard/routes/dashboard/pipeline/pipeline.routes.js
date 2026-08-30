import { frontendURL } from '../../../helper/URLHelper';
import PipelineIndex from './Index.vue';

const meta = {
  permissions: ['administrator', 'agent', 'custom_role'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipeline'),
    component: PipelineIndex,
    name: 'pipeline_view',
    meta,
  },
];
