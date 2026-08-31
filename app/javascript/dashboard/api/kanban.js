/* global axios */
import ApiClient from './ApiClient';

class KanbanPipelinesAPI extends ApiClient {
  constructor() {
    super('kanban/pipelines', { accountScoped: true });
  }
}

class KanbanTasksAPI extends ApiClient {
  constructor() {
    super('kanban/tasks', { accountScoped: true });
  }

  list(params) {
    return axios.get(this.url, { params });
  }

  move(taskId, { stageId, position }) {
    return axios.patch(`${this.url}/${taskId}/move`, {
      stage_id: stageId,
      position,
    });
  }
}

export const KanbanPipelines = new KanbanPipelinesAPI();
export const KanbanTasks = new KanbanTasksAPI();
