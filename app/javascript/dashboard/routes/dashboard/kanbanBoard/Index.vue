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
import BoardColumn from './components/BoardColumn.vue';
import PipelineSwitcher from './components/PipelineSwitcher.vue';
import PipelineSettings from './components/PipelineSettings.vue';
import NewPipelineDialog from './components/NewPipelineDialog.vue';
import TaskDialog from './components/TaskDialog.vue';

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();

const settingsRef = ref(null);
const newPipelineRef = ref(null);
const taskDialogRef = ref(null);
const showMetrics = ref(false);

const pipelines = useMapGetter('kanban/getPipelines');
const activePipeline = useMapGetter('kanban/getActivePipeline');
const tasksByStage = useMapGetter('kanban/getTasksByStage');
const uiFlags = useMapGetter('kanban/getUIFlags');
const metrics = useMapGetter('kanban/getMetrics');
const stageMetrics = useMapGetter('kanban/getStageMetrics');

const stages = computed(() => activePipeline.value?.stages || []);
const isLoading = computed(
  () => uiFlags.value.isFetchingPipelines || uiFlags.value.isFetchingTasks
);

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

const onAddTask = stage => taskDialogRef.value?.open(null, stage.id);

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
      class="flex flex-wrap items-center justify-between flex-shrink-0 gap-3 px-4 py-3 border-b border-n-weak"
    >
      <div>
        <h1 class="m-0 text-base font-medium text-n-slate-12">
          {{ activePipeline?.name || t('KANBAN.BOARD.TITLE') }}
        </h1>
        <p v-if="showMetrics && metrics" class="m-0 text-xs text-n-slate-11">
          {{
            t('KANBAN.METRICS.SUMMARY', {
              total: metrics.totals.card_count,
              won: metrics.totals.won_count,
              lost: metrics.totals.lost_count,
              rate: metrics.totals.win_rate ?? '—',
            })
          }}
        </p>
        <p v-else class="m-0 text-xs text-n-slate-11">
          {{ activePipeline?.description || t('KANBAN.BOARD.SUBTITLE') }}
        </p>
      </div>
      <div class="flex items-center gap-2">
        <PipelineSwitcher
          :pipelines="pipelines"
          :active-pipeline-id="activePipeline?.id"
          @select="onSelectPipeline"
        />
        <Button
          variant="faded"
          :color="showMetrics ? 'blue' : 'slate'"
          size="sm"
          icon="i-lucide-chart-no-axes-column"
          :label="t('KANBAN.METRICS.TOGGLE')"
          @click="onToggleMetrics"
        />
        <template v-if="isAdmin">
          <Button
            variant="faded"
            color="slate"
            size="sm"
            icon="i-lucide-plus"
            :label="t('KANBAN.BOARD.NEW_PIPELINE')"
            @click="newPipelineRef?.open()"
          />
          <Button
            v-if="activePipeline"
            variant="faded"
            color="slate"
            size="sm"
            icon="i-lucide-settings-2"
            :aria-label="t('KANBAN.BOARD.SETTINGS')"
            @click="settingsRef?.open()"
          />
        </template>
      </div>
    </header>

    <div
      v-if="isLoading && !stages.length"
      class="flex items-center justify-center flex-1"
    >
      <Spinner />
    </div>

    <div v-else class="flex flex-1 gap-3 p-3 overflow-x-auto">
      <BoardColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        :tasks="tasksByStage(stage.id)"
        :metrics="showMetrics ? stageMetrics(stage.id) : null"
        @drop="onDrop"
        @open-task="onOpenTask"
        @edit-task="onEditTask"
        @add-task="onAddTask"
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
