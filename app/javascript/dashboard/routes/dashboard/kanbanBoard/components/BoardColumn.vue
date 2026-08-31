<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import BoardCard from './BoardCard.vue';

const props = defineProps({
  stage: { type: Object, required: true },
  tasks: { type: Array, default: () => [] },
});

const emit = defineEmits(['drop', 'open-task']);

const { t } = useI18n();

const stageIcon = computed(() => {
  if (props.stage.is_won_stage) return 'i-lucide-circle-check-big';
  if (props.stage.is_lost_stage) return 'i-lucide-circle-x';
  return 'i-lucide-circle-dot';
});

// vuedraggable mutates the bound list; the board owns the source of truth, so the
// column reports the intent and lets the parent reconcile with the server.
const draggableList = computed({
  get: () => props.tasks,
  set: () => {},
});

const onChange = event => {
  const change = event.added || event.moved;
  if (!change) return;
  emit('drop', {
    taskId: change.element.id,
    stageId: props.stage.id,
    position: change.newIndex,
  });
};
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 w-[272px] rounded-xl border border-n-weak bg-n-solid-2/60"
  >
    <div class="flex items-center gap-2 px-3 pt-3 pb-2.5 border-b border-n-weak">
      <span
        class="flex items-center justify-center rounded-md size-5"
        :style="{ backgroundColor: `${stage.color_hex}26`, color: stage.color_hex }"
      >
        <Icon :icon="stageIcon" class="size-3" />
      </span>
      <h3 class="flex-1 min-w-0 m-0 text-sm font-medium truncate text-n-slate-12">
        {{ stage.name }}
      </h3>
      <span
        class="px-1.5 py-0.5 rounded-full text-xs leading-none bg-n-solid-3 text-n-slate-11 tabular-nums"
      >
        {{ tasks.length }}
      </span>
    </div>

    <Draggable
      v-model="draggableList"
      :group="{ name: 'kanban-cards' }"
      item-key="id"
      animation="180"
      ghost-class="opacity-40"
      class="flex flex-col flex-1 gap-2 p-2 overflow-y-auto min-h-[120px] max-h-[calc(100vh-200px)]"
      @change="onChange"
    >
      <template #item="{ element }">
        <BoardCard
          :task="element"
          :stage-color="stage.color_hex"
          @open="emit('open-task', $event)"
        />
      </template>
      <template #footer>
        <p
          v-if="!tasks.length"
          class="py-6 m-0 text-xs italic text-center text-n-slate-9"
        >
          {{ t('KANBAN.BOARD.EMPTY_STAGE') }}
        </p>
      </template>
    </Draggable>
  </div>
</template>
