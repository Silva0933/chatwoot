<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import BoardCard from './BoardCard.vue';
import { formatDuration, readableTextOn } from '../constants';

const props = defineProps({
  stage: { type: Object, required: true },
  tasks: { type: Array, default: () => [] },
  metrics: { type: Object, default: null },
  canEdit: { type: Boolean, default: false },
});

const emit = defineEmits([
  'drop',
  'open-task',
  'edit-task',
  'add-task',
  'configure',
]);

const { t } = useI18n();

const headerText = computed(() => readableTextOn(props.stage.color_hex));

// The count pill and the two buttons sit on the stage's own colour, so they are
// tinted from the header's text colour rather than from a fixed palette.
const onHeaderSoft = computed(() =>
  headerText.value === '#FFFFFF' ? 'rgba(0,0,0,0.22)' : 'rgba(255,255,255,0.35)'
);

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
    class="flex flex-col flex-shrink-0 w-[290px] overflow-hidden border rounded-xl border-n-weak bg-n-solid-1"
  >
    <header
      class="flex items-center gap-2 px-3 py-2"
      :style="{ backgroundColor: stage.color_hex, color: headerText }"
    >
      <h3 class="flex-1 min-w-0 m-0 text-sm font-semibold truncate">
        {{ stage.name }}
      </h3>

      <span
        class="px-1.5 py-0.5 rounded-md text-xs font-medium leading-none tabular-nums"
        :style="{ backgroundColor: onHeaderSoft }"
      >
        {{ tasks.length }}
      </span>

      <template v-if="canEdit">
        <button
          type="button"
          class="flex items-center justify-center transition-opacity rounded size-5 opacity-70 hover:opacity-100"
          :aria-label="t('KANBAN.BOARD.SETTINGS')"
          @click="emit('configure')"
        >
          <Icon icon="i-lucide-settings" class="size-3.5" />
        </button>
        <button
          type="button"
          class="flex items-center justify-center transition-opacity rounded size-5 opacity-70 hover:opacity-100"
          :aria-label="t('KANBAN.TASK.NEW_TITLE')"
          @click="emit('add-task', stage)"
        >
          <Icon icon="i-lucide-plus" class="size-4" />
        </button>
      </template>
    </header>

    <div
      v-if="metrics"
      class="flex items-center justify-between gap-2 px-3 py-1.5 border-b border-n-weak text-[11px] text-n-slate-11 bg-n-solid-2"
    >
      <span :title="t('KANBAN.METRICS.AVERAGE_TIME')">
        <Icon icon="i-lucide-timer" class="inline size-3" />
        {{ formatDuration(metrics.average_seconds_in_stage, t) }}
      </span>
      <span :title="t('KANBAN.METRICS.ENTERED')">
        <Icon icon="i-lucide-log-in" class="inline size-3" />
        {{ metrics.entered_count }}
      </span>
      <span
        v-if="metrics.passage_rate !== null"
        :title="t('KANBAN.METRICS.PASSAGE_RATE')"
      >
        <Icon icon="i-lucide-trending-up" class="inline size-3" />
        {{ metrics.passage_rate }}%
      </span>
    </div>

    <Draggable
      v-model="draggableList"
      :group="{ name: 'kanban-cards' }"
      item-key="id"
      animation="180"
      ghost-class="opacity-40"
      class="flex flex-col flex-1 gap-2 p-2 overflow-y-auto min-h-[120px] max-h-[calc(100vh-190px)]"
      @change="onChange"
    >
      <template #item="{ element }">
        <BoardCard
          :task="element"
          @open="emit('open-task', $event)"
          @edit="emit('edit-task', $event)"
        />
      </template>
      <template #footer>
        <p
          v-if="!tasks.length"
          class="py-8 m-0 text-xs italic text-center text-n-slate-9"
        >
          {{ t('KANBAN.BOARD.EMPTY_STAGE') }}
        </p>
      </template>
    </Draggable>
  </div>
</template>
