<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { KanbanTasks, KanbanPipelines } from 'dashboard/api/kanban';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
});

const { t } = useI18n();

// Local state rather than the board's Vuex module: that module holds one
// pipeline's cards for the board screen, and the sidebar asks a different
// question — every card that points at this conversation.
const tasks = ref([]);
const stagesByPipeline = ref({});
const isLoading = ref(false);

const fetchCard = async () => {
  isLoading.value = true;
  try {
    const [{ data: taskData }, { data: pipelineData }] = await Promise.all([
      KanbanTasks.list({ conversation_id: props.conversationId }),
      KanbanPipelines.get(),
    ]);
    tasks.value = taskData.payload;
    stagesByPipeline.value = Object.fromEntries(
      pipelineData.payload.map(pipeline => [pipeline.id, pipeline])
    );
  } finally {
    isLoading.value = false;
  }
};

const onChangeStage = async (task, stageId) => {
  try {
    const { data } = await KanbanTasks.move(task.id, { stageId });
    tasks.value = tasks.value.map(record =>
      record.id === data.id ? data : record
    );
  } catch (error) {
    useAlert(t('KANBAN.SIDEBAR.MOVE_ERROR'));
  }
};

watch(() => props.conversationId, fetchCard, { immediate: true });
</script>

<template>
  <div class="flex flex-col gap-2">
    <Spinner v-if="isLoading" class="self-center" />

    <p v-else-if="!tasks.length" class="m-0 text-sm text-n-slate-11">
      {{ t('KANBAN.SIDEBAR.NO_CARD') }}
    </p>

    <template v-else>
      <div v-for="task in tasks" :key="task.id" class="flex flex-col gap-1">
        <span class="text-xs text-n-slate-10">
          {{ stagesByPipeline[task.pipeline_id]?.name }}
        </span>
        <select
          :value="task.stage_id"
          class="px-2.5 py-1.5 text-sm border rounded-lg border-n-weak bg-n-solid-1 text-n-slate-12"
          @change="onChangeStage(task, Number($event.target.value))"
        >
          <option
            v-for="stage in stagesByPipeline[task.pipeline_id]?.stages || []"
            :key="stage.id"
            :value="stage.id"
          >
            {{ stage.name }}
          </option>
        </select>
      </div>
    </template>
  </div>
</template>
