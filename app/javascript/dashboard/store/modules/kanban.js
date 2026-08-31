import types from '../mutation-types';
import {
  KanbanPipelines,
  KanbanStages,
  KanbanMembers,
  KanbanAutomations,
  KanbanTasks,
} from '../../api/kanban';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

// Settings writes all follow the same shape: flag the UI as busy, hit the API and
// then reload the pipelines so the board and the settings screen agree.
const withSettingsFlag = async ({ commit, dispatch }, request) => {
  commit(types.SET_KANBAN_UI_FLAG, { isSavingSettings: true });
  try {
    await request();
    await dispatch('fetchPipelines');
  } finally {
    commit(types.SET_KANBAN_UI_FLAG, { isSavingSettings: false });
  }
};

export const state = {
  pipelines: [],
  activePipelineId: null,
  records: [],
  uiFlags: {
    isFetchingPipelines: false,
    isFetchingTasks: false,
    isMoving: false,
    isSavingSettings: false,
  },
  templates: [],
  metrics: null,
  members: [],
};

export const getters = {
  getPipelines($state) {
    return $state.pipelines;
  },
  getActivePipeline($state) {
    return (
      $state.pipelines.find(p => p.id === $state.activePipelineId) ||
      $state.pipelines[0] ||
      null
    );
  },
  getTasks($state) {
    return $state.records;
  },
  getTasksByStage: $state => stageId => {
    return $state.records
      .filter(task => task.stage_id === stageId)
      .sort((a, b) => a.position - b.position);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getTemplates($state) {
    return $state.templates;
  },
  getMetrics($state) {
    return $state.metrics;
  },
  getMembers($state) {
    return $state.members;
  },
  getStageMetrics: $state => stageId =>
    $state.metrics?.stages?.find(stage => stage.id === stageId) || null,
  getTaskCountByStage: $state => {
    return $state.records.reduce((counts, task) => {
      counts[task.stage_id] = (counts[task.stage_id] || 0) + 1;
      return counts;
    }, {});
  },
};

export const actions = {
  fetchPipelines: async ({ commit, state: $state }) => {
    commit(types.SET_KANBAN_UI_FLAG, { isFetchingPipelines: true });
    try {
      const { data } = await KanbanPipelines.get();
      commit(types.SET_KANBAN_PIPELINES, data.payload);
      if (!$state.activePipelineId && data.payload.length) {
        commit(types.SET_KANBAN_ACTIVE_PIPELINE, data.payload[0].id);
      }
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isFetchingPipelines: false });
    }
  },

  createPipeline: async ({ commit }, payload) => {
    const { data } = await KanbanPipelines.create({ pipeline: payload });
    commit(types.ADD_KANBAN_PIPELINE, data);
    commit(types.SET_KANBAN_ACTIVE_PIPELINE, data.id);
    return data;
  },

  setActivePipeline: ({ commit }, pipelineId) => {
    commit(types.SET_KANBAN_ACTIVE_PIPELINE, pipelineId);
  },

  fetchTasks: async ({ commit }, { pipelineId }) => {
    commit(types.SET_KANBAN_UI_FLAG, { isFetchingTasks: true });
    try {
      const { data } = await KanbanTasks.list({ pipeline_id: pipelineId });
      commit(types.SET_KANBAN_TASKS, data.payload);
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isFetchingTasks: false });
    }
  },

  // Moves optimistically so the dragged card stays where it was dropped instead of
  // snapping back while the request is in flight; a failure refetches, because by
  // then the local list holds a position the server never accepted.
  moveTask: async ({ commit, dispatch, state: $state }, { taskId, stageId, position }) => {
    const current = $state.records.find(task => task.id === taskId);
    if (current) {
      commit(types.EDIT_KANBAN_TASK, {
        ...current,
        stage_id: stageId,
        position,
        stage_entered_at:
          current.stage_id === stageId
            ? current.stage_entered_at
            : new Date().toISOString(),
      });
    }

    commit(types.SET_KANBAN_UI_FLAG, { isMoving: true });
    try {
      const { data } = await KanbanTasks.move(taskId, { stageId, position });
      commit(types.EDIT_KANBAN_TASK, data);
      return data;
    } catch (error) {
      await dispatch('fetchTasks', { pipelineId: $state.activePipelineId });
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isMoving: false });
    }
  },

  fetchTemplates: async ({ commit, state: $state }) => {
    if ($state.templates.length) return $state.templates;

    const { data } = await KanbanPipelines.templates();
    commit(types.SET_KANBAN_TEMPLATES, data.payload);
    return data.payload;
  },

  fetchMetrics: async ({ commit }, { pipelineId }) => {
    const { data } = await KanbanPipelines.metrics(pipelineId);
    commit(types.SET_KANBAN_METRICS, data);
    return data;
  },

  fetchMembers: async ({ commit }, { pipelineId }) => {
    const { data } = await KanbanMembers.list(pipelineId);
    commit(types.SET_KANBAN_MEMBERS, data.payload);
    return data.payload;
  },

  // Membership decides who can see the funnel, so both writes refetch: the list is
  // small and it keeps the screen from disagreeing with the access rule.
  addMember: async ({ dispatch }, { pipelineId, userId }) => {
    await KanbanMembers.create(pipelineId, userId);
    await dispatch('fetchMembers', { pipelineId });
  },

  updateMemberRole: async ({ dispatch }, { pipelineId, userId, role }) => {
    await KanbanMembers.update(pipelineId, userId, role);
    await dispatch('fetchMembers', { pipelineId });
  },

  removeMember: async ({ dispatch }, { pipelineId, userId }) => {
    await KanbanMembers.delete(pipelineId, userId);
    await dispatch('fetchMembers', { pipelineId });
  },

  updatePipeline: async ({ commit }, { id, ...payload }) => {
    const { data } = await KanbanPipelines.update(id, { pipeline: payload });
    commit(types.EDIT_KANBAN_PIPELINE, data);
    return data;
  },

  deletePipeline: async ({ commit, dispatch }, id) => {
    await KanbanPipelines.delete(id);
    commit(types.DELETE_KANBAN_PIPELINE, id);
    await dispatch('fetchPipelines');
  },

  // Every stage write refetches the pipelines instead of patching state by hand:
  // renaming a terminal column can silently demote another one server-side, so the
  // returned stage alone is not enough to keep the board honest.
  createStage: async ({ commit, dispatch }, { pipelineId, ...stage }) => {
    await withSettingsFlag({ commit, dispatch }, () =>
      KanbanStages.create(pipelineId, stage)
    );
  },

  updateStage: async ({ commit, dispatch }, { pipelineId, id, ...stage }) => {
    await withSettingsFlag({ commit, dispatch }, () =>
      KanbanStages.update(pipelineId, id, stage)
    );
  },

  deleteStage: async (
    { commit, dispatch, state: $state },
    { pipelineId, id, moveTasksToStageId }
  ) => {
    await withSettingsFlag({ commit, dispatch }, () =>
      KanbanStages.delete(pipelineId, id, { moveTasksToStageId })
    );
    await dispatch('fetchTasks', { pipelineId: $state.activePipelineId });
  },

  reorderStages: async ({ commit, dispatch }, { pipelineId, stageIds }) => {
    await withSettingsFlag({ commit, dispatch }, () =>
      KanbanStages.reorder(pipelineId, stageIds)
    );
  },

  updateAutomation: async ({ commit, dispatch }, { pipelineId, ...automation }) => {
    await withSettingsFlag({ commit, dispatch }, () =>
      KanbanAutomations.update(pipelineId, automation)
    );
  },

  // Broadcasts carry push_event_data, which has none of the nested contact, agent
  // or channel the card renders, so the canonical record is fetched instead of
  // merged. A board sees a handful of these a minute, so one request each is fine.
  syncTaskFromCable: async (
    { commit, state: $state, rootGetters },
    { task, performer }
  ) => {
    if (!task || task.pipeline_id !== $state.activePipelineId) return;
    if (performer?.id === rootGetters.getCurrentUserID) return;

    const { data } = await KanbanTasks.show(task.id);
    const exists = $state.records.some(record => record.id === data.id);
    commit(exists ? types.EDIT_KANBAN_TASK : types.ADD_KANBAN_TASK, data);
  },

  // Columns are structure, not content: a rename or a reorder has to reach every
  // open board, and the admin who made the change already has it.
  syncPipelineFromCable: ({ dispatch, rootGetters }, { pipeline, performer }) => {
    if (!pipeline) return;
    if (performer?.id === rootGetters.getCurrentUserID) return;

    dispatch('fetchPipelines');
  },

  removeTaskFromCable: ({ commit, state: $state }, { task }) => {
    if (!task || task.pipeline_id !== $state.activePipelineId) return;

    commit(types.DELETE_KANBAN_TASK, task.id);
  },

  createTask: async ({ commit }, payload) => {
    const { data } = await KanbanTasks.create({ task: payload });
    commit(types.ADD_KANBAN_TASK, data);
    return data;
  },

  updateTask: async ({ commit }, { id, ...payload }) => {
    const { data } = await KanbanTasks.update(id, { task: payload });
    commit(types.EDIT_KANBAN_TASK, data);
    return data;
  },

  deleteTask: async ({ commit }, id) => {
    await KanbanTasks.delete(id);
    commit(types.DELETE_KANBAN_TASK, id);
  },
};

export const mutations = {
  [types.SET_KANBAN_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_KANBAN_PIPELINES]($state, data) {
    $state.pipelines = data;
  },
  [types.ADD_KANBAN_PIPELINE]($state, data) {
    $state.pipelines.push(data);
  },
  [types.EDIT_KANBAN_PIPELINE]($state, data) {
    $state.pipelines = $state.pipelines.map(pipeline =>
      pipeline.id === data.id ? data : pipeline
    );
  },
  [types.DELETE_KANBAN_PIPELINE]($state, id) {
    $state.pipelines = $state.pipelines.filter(pipeline => pipeline.id !== id);
    if ($state.activePipelineId === id) $state.activePipelineId = null;
  },
  [types.SET_KANBAN_TEMPLATES]($state, data) {
    $state.templates = data;
  },
  [types.SET_KANBAN_METRICS]($state, data) {
    $state.metrics = data;
  },
  [types.SET_KANBAN_MEMBERS]($state, data) {
    $state.members = data;
  },
  [types.SET_KANBAN_ACTIVE_PIPELINE]($state, pipelineId) {
    $state.activePipelineId = pipelineId;
  },
  [types.SET_KANBAN_TASKS]: MutationHelpers.set,
  [types.ADD_KANBAN_TASK]: MutationHelpers.create,
  [types.EDIT_KANBAN_TASK]: MutationHelpers.update,
  [types.DELETE_KANBAN_TASK]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
