<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { provideDropdownTeleport } from 'dashboard/components-next/dropdown-menu/base/provider.js';
import BoardCard from './BoardCard.vue';
import { formatDuration, readableTextOn, formatMoney } from '../constants';

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

const { t, locale } = useI18n();

// The card list scrolls inside the column, which would clip a card menu opened
// near the bottom. Teleporting the menus to <body> is what the primitives offer
// for exactly this case.
provideDropdownTeleport();

const headerText = computed(() => readableTextOn(props.stage.color_hex));

const columnValue = computed(() =>
  formatMoney(
    props.tasks.reduce((sum, task) => sum + (task.value_cents || 0), 0),
    locale.value
  )
);

// The WIP limit is the rule the method is named after: a column over its limit
// is where the funnel is actually stuck, so it says so on the column itself.
const overWipLimit = computed(
  () => !!props.stage.wip_limit && props.tasks.length > props.stage.wip_limit
);

// The count pill and the two buttons sit on the stage's own colour, so they are
// tinted from the header's text colour rather than from a fixed palette.
const onHeaderSoft = computed(() =>
  headerText.value === '#FFFFFF' ? 'rgba(0,0,0,0.22)' : 'rgba(255,255,255,0.35)'
);

// Won and lost are where the funnel ends, and the eye should be able to find them
// without reading the headers. The colour is the border only — filling the column
// would compete with the cards inside it.
const outline = computed(() => {
  if (props.stage.is_won_stage) return 'border-n-teal-8/70';
  if (props.stage.is_lost_stage) return 'border-n-ruby-8/70';
  return 'border-n-weak';
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
    class="flex flex-col flex-shrink-0 w-[85vw] max-w-[300px] sm:w-[300px] h-full min-h-0 overflow-hidden border rounded-2xl bg-n-solid-1"
    :class="outline"
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
        :title="
          stage.wip_limit ? t('KANBAN.BOARD.WIP_LIMIT', { limit: stage.wip_limit }) : ''
        "
      >
        {{ tasks.length }}<template v-if="stage.wip_limit">/{{ stage.wip_limit }}</template>
      </span>

      <Icon
        v-if="overWipLimit"
        icon="i-lucide-triangle-alert"
        class="flex-shrink-0 size-3.5"
        :title="t('KANBAN.BOARD.WIP_EXCEEDED')"
      />

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
      v-if="columnValue"
      class="flex items-center justify-between gap-2 px-3 py-1.5 text-[11px] border-b border-n-weak bg-n-solid-2"
      :title="t('KANBAN.BOARD.COLUMN_VALUE')"
    >
      <span class="uppercase tracking-wide text-[10px] text-n-slate-10">
        {{ t('KANBAN.BOARD.COLUMN_VALUE_SHORT') }}
      </span>
      <span class="font-semibold text-n-teal-11 tabular-nums">
        {{ columnValue }}
      </span>
    </div>

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
      class="flex flex-col flex-1 min-h-0 gap-2 p-2 overflow-y-auto"
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
        <!-- An empty column is the one place on the board with room to say what to
             do next, and the drop target reads better outlined than as a caption. -->
        <component
          :is="canEdit ? 'button' : 'div'"
          v-if="!tasks.length"
          :type="canEdit ? 'button' : null"
          class="flex flex-col items-center justify-center w-full gap-1.5 py-10 text-xs transition-colors border border-dashed rounded-xl border-n-weak text-n-slate-10"
          :class="
            canEdit ? 'hover:border-n-slate-6 hover:text-n-slate-11' : 'cursor-default'
          "
          @click="canEdit && emit('add-task', stage)"
        >
          <Icon v-if="canEdit" icon="i-lucide-plus" class="size-4" />
          <span>{{ t('KANBAN.BOARD.EMPTY_STAGE') }}</span>
          <span v-if="canEdit" class="text-n-slate-9">
            {{ t('KANBAN.BOARD.EMPTY_STAGE_ACTION') }}
          </span>
        </component>
      </template>
    </Draggable>
  </div>
</template>
