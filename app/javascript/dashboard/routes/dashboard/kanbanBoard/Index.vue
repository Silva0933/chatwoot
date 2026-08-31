<script setup>
import { computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import BoardColumn from './components/BoardColumn.vue';
import PipelineSwitcher from './components/PipelineSwitcher.vue';

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();

const pipelines = useMapGetter('kanban/getPipelines');
const activePipeline = useMapGetter('kanban/getActivePipeline');
const tasksByStage = useMapGetter('kanban/getTasksByStage');
const uiFlags = useMapGetter('kanban/getUIFlags');

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
        <p class="m-0 text-xs text-n-slate-11">
          {{ activePipeline?.description || t('KANBAN.BOARD.SUBTITLE') }}
        </p>
      </div>
      <PipelineSwitcher
        :pipelines="pipelines"
        :active-pipeline-id="activePipeline?.id"
        @select="onSelectPipeline"
      />
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
        @drop="onDrop"
        @open-task="onOpenTask"
      />
    </div>
  </section>
</template>
