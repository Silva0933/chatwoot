<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import BoardColumn from './components/BoardColumn.vue';
import BoardFilters from './components/BoardFilters.vue';
import PipelineSwitcher from './components/PipelineSwitcher.vue';
import PipelineSettings from './components/PipelineSettings.vue';
import NewPipelineDialog from './components/NewPipelineDialog.vue';
import TaskDialog from './components/TaskDialog.vue';
import { SORT_OPTIONS, sortTasks } from './constants';

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();

const settingsRef = ref(null);
const newPipelineRef = ref(null);
const taskDialogRef = ref(null);
const showMetrics = ref(false);
const agentFilter = ref('');
const inboxFilter = ref('');
const sortBy = ref(SORT_OPTIONS[0].value);

const pipelines = useMapGetter('kanban/getPipelines');
const activePipeline = useMapGetter('kanban/getActivePipeline');
const tasksByStage = useMapGetter('kanban/getTasksByStage');
const allTasks = useMapGetter('kanban/getTasks');
const uiFlags = useMapGetter('kanban/getUIFlags');
const metrics = useMapGetter('kanban/getMetrics');
const stageMetrics = useMapGetter('kanban/getStageMetrics');

const stages = computed(() => activePipeline.value?.stages || []);
const isLoading = computed(
  () => uiFlags.value.isFetchingPipelines || uiFlags.value.isFetchingTasks
);

// Filtering runs over the cards already in memory. The board loads the whole
// pipeline anyway, so a round trip per filter change would only add latency.
//
// tasksByStage is a ref holding the getter, and only templates unwrap refs for
// you. Calling it from script has to go through .value.
const visibleTasks = stageId => {
  const filtered = tasksByStage.value(stageId).filter(task => {
    if (agentFilter.value && task.assigned_agent?.id !== agentFilter.value) {
      return false;
    }
    return !(inboxFilter.value && task.inbox_id !== inboxFilter.value);
  });

  return sortTasks(filtered, sortBy.value);
};

const visibleCount = computed(
  () => stages.value.reduce((sum, s) => sum + visibleTasks(s.id).length, 0)
);

const isFiltered = computed(() => !!(agentFilter.value || inboxFilter.value));

onMounted(async () => {
  await store.dispatch('kanban/fetchPipelines');
});

watch(
  () => activePipeline.value?.id,
  pipelineId => {
    if (pipelineId) store.dispatch('kanban/fetchTasks', { pipelineId });
  },
  { immediate: true }
);

const onSelectPipeline = pipelineId => {
  store.dispatch('kanban/setActivePipeline', pipelineId);
};

const onDrop = async ({ taskId, stageId, position }) => {
  try {
    await store.dispatch('kanban/moveTask', { taskId, stageId, position });
  } catch (error) {
    useAlert(t('KANBAN.BOARD.MOVE_ERROR'));
  }
};

const onOpenTask = task => {
  if (!task.conversation_id) return;
  router.push({
    name: 'inbox_conversation',
    params: { accountId: accountId.value, conversation_id: task.conversation_id },
  });
};

// The X-ray is off by default: it costs an extra query over the transition log and
// most of the time an agent just wants to see the cards.
const onToggleMetrics = async () => {
  showMetrics.value = !showMetrics.value;
  if (!showMetrics.value || !activePipeline.value) return;

  try {
    await store.dispatch('kanban/fetchMetrics', {
      pipelineId: activePipeline.value.id,
    });
  } catch (error) {
    showMetrics.value = false;
    useAlert(t('KANBAN.METRICS.ERROR'));
  }
};

const onEditTask = task => taskDialogRef.value?.open(task);

const onAddTask = stage => taskDialogRef.value?.open(null, stage?.id);

const onPipelineCreated = pipeline => {
  store.dispatch('kanban/fetchTasks', { pipelineId: pipeline.id });
};

// The deleted pipeline was the active one, so the store cleared the selection and
// the getter falls back to the first remaining funnel; its cards still have to load.
const onPipelineDeleted = () => {
  if (activePipeline.value) {
    store.dispatch('kanban/fetchTasks', { pipelineId: activePipeline.value.id });
  }
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header
      class="flex items-center gap-2 px-4 py-2.5 flex-shrink-0 overflow-x-auto border-b border-n-weak"
    >
      <div class="flex items-center gap-2 mr-1">
        <h1 class="m-0 text-sm font-semibold text-n-slate-12">
          {{ activePipeline?.name || t('KANBAN.BOARD.TITLE') }}
        </h1>
        <span
          class="px-1.5 py-0.5 rounded-md text-xs leading-none tabular-nums bg-n-solid-3 text-n-slate-11"
          :title="
            isFiltered ? t('KANBAN.BOARD.FILTERED_COUNT') : t('KANBAN.BOARD.TOTAL')
          "
        >
          {{ visibleCount }}
        </span>
      </div>

      <PipelineSwitcher
        :pipelines="pipelines"
        :active-pipeline-id="activePipeline?.id"
        @select="onSelectPipeline"
      />

      <div class="flex items-center flex-shrink-0 gap-2 ml-auto">
        <BoardFilters
          v-model:agent-id="agentFilter"
          v-model:inbox-id="inboxFilter"
          v-model:sort-by="sortBy"
          :tasks="allTasks"
        />

        <Button
          variant="faded"
          :color="showMetrics ? 'blue' : 'slate'"
          size="sm"
          icon="i-lucide-chart-no-axes-column"
          :label="t('KANBAN.METRICS.TOGGLE')"
          @click="onToggleMetrics"
        />

        <Button
          v-if="isAdmin"
          variant="faded"
          color="slate"
          size="sm"
          icon="i-lucide-settings-2"
          :aria-label="t('KANBAN.BOARD.SETTINGS')"
          @click="settingsRef?.open()"
        />

        <Button
          v-if="isAdmin"
          variant="faded"
          color="slate"
          size="sm"
          icon="i-lucide-git-fork"
          :aria-label="t('KANBAN.BOARD.NEW_PIPELINE')"
          @click="newPipelineRef?.open()"
        />

        <Button
          variant="solid"
          color="blue"
          size="sm"
          icon="i-lucide-plus"
          :label="t('KANBAN.TASK.NEW_TITLE')"
          :disabled="!activePipeline"
          @click="onAddTask(null)"
        />
      </div>
    </header>

    <p
      v-if="showMetrics && metrics"
      class="flex-shrink-0 px-4 py-1.5 m-0 text-xs border-b border-n-weak text-n-slate-11 bg-n-solid-1"
    >
      {{
        t('KANBAN.METRICS.SUMMARY', {
          total: metrics.totals.card_count,
          won: metrics.totals.won_count,
          lost: metrics.totals.lost_count,
          rate: metrics.totals.win_rate ?? '—',
        })
      }}
    </p>

    <div
      v-if="isLoading && !stages.length"
      class="flex items-center justify-center flex-1"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!stages.length"
      class="flex flex-col items-center justify-center flex-1 gap-2 text-n-slate-10"
    >
      <Icon icon="i-lucide-columns-3" class="size-8" />
      <p class="m-0 text-sm">{{ t('KANBAN.BOARD.EMPTY') }}</p>
    </div>

    <div v-else class="flex flex-1 min-h-0 gap-3 p-3 overflow-x-auto">
      <BoardColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        :tasks="visibleTasks(stage.id)"
        :metrics="showMetrics ? stageMetrics(stage.id) : null"
        :can-edit="isAdmin"
        @drop="onDrop"
        @open-task="onOpenTask"
        @edit-task="onEditTask"
        @add-task="onAddTask"
        @configure="settingsRef?.open()"
      />
    </div>

    <TaskDialog
      v-if="activePipeline"
      ref="taskDialogRef"
      :pipeline="activePipeline"
    />

    <template v-if="isAdmin">
      <PipelineSettings
        v-if="activePipeline"
        ref="settingsRef"
        :key="activePipeline.id"
        :pipeline="activePipeline"
        @deleted="onPipelineDeleted"
      />
      <NewPipelineDialog ref="newPipelineRef" @created="onPipelineCreated" />
    </template>
  </section>
</template>
