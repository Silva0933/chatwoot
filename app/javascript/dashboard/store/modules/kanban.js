import types from '../mutation-types';
import { KanbanPipelines, KanbanTasks } from '../../api/kanban';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

export const state = {
  pipelines: [],
  activePipelineId: null,
  records: [],
  uiFlags: {
    isFetchingPipelines: false,
    isFetchingTasks: false,
    isMoving: false,
  },
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
