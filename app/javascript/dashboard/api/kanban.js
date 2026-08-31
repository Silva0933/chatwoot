/* global axios */
import ApiClient from './ApiClient';

class KanbanPipelinesAPI extends ApiClient {
  constructor() {
    super('kanban/pipelines', { accountScoped: true });
  }

  templates() {
    return axios.get(`${this.url}/templates`);
  }

  metrics(pipelineId) {
    return axios.get(`${this.url}/${pipelineId}/metrics`);
  }
}

// Stages and automations are nested under a pipeline, so they share the pipelines
// base url instead of getting a resource of their own.
class KanbanStagesAPI extends ApiClient {
  constructor() {
    super('kanban/pipelines', { accountScoped: true });
  }

  stagesUrl(pipelineId) {
    return `${this.url}/${pipelineId}/stages`;
  }

  create(pipelineId, stage) {
    return axios.post(this.stagesUrl(pipelineId), { stage });
  }

  update(pipelineId, stageId, stage) {
    return axios.patch(`${this.stagesUrl(pipelineId)}/${stageId}`, { stage });
  }

  delete(pipelineId, stageId, { moveTasksToStageId } = {}) {
    return axios.delete(`${this.stagesUrl(pipelineId)}/${stageId}`, {
      params: { move_tasks_to_stage_id: moveTasksToStageId },
    });
  }

  reorder(pipelineId, stageIds) {
    return axios.post(`${this.stagesUrl(pipelineId)}/reorder`, {
      stage_ids: stageIds,
    });
  }
}

class KanbanMembersAPI extends ApiClient {
  constructor() {
    super('kanban/pipelines', { accountScoped: true });
  }

  membersUrl(pipelineId) {
    return `${this.url}/${pipelineId}/members`;
  }

  list(pipelineId) {
    return axios.get(this.membersUrl(pipelineId));
  }

  create(pipelineId, userId) {
    return axios.post(this.membersUrl(pipelineId), { user_id: userId });
  }

  update(pipelineId, userId, role) {
    return axios.patch(`${this.membersUrl(pipelineId)}/${userId}`, { role });
  }

  delete(pipelineId, userId) {
    return axios.delete(`${this.membersUrl(pipelineId)}/${userId}`);
  }
}

class KanbanAutomationsAPI extends ApiClient {
  constructor() {
    super('kanban/pipelines', { accountScoped: true });
  }

  show(pipelineId) {
    return axios.get(`${this.url}/${pipelineId}/automation`);
  }

  update(pipelineId, automation) {
    return axios.patch(`${this.url}/${pipelineId}/automation`, { automation });
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
export const KanbanStages = new KanbanStagesAPI();
export const KanbanMembers = new KanbanMembersAPI();
export const KanbanAutomations = new KanbanAutomationsAPI();
export const KanbanTasks = new KanbanTasksAPI();
