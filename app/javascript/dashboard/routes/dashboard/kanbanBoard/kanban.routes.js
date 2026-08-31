import { frontendURL } from '../../../helper/URLHelper';
import KanbanBoard from './Index.vue';

const meta = {
  permissions: ['administrator', 'agent', 'custom_role'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/kanban-board'),
    component: KanbanBoard,
    name: 'kanban_board',
    meta,
  },
];
