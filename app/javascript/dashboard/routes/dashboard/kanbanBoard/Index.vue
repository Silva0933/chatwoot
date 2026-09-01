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
import { SORT_OPTIONS, sortTasks, boardStats, formatMoney } from './constants';

const store = useStore();
const router = useRouter();
const { t, locale } = useI18n();
const { accountId } = useAccount();
const { isAdmin } = useAdmin();

const settingsRef = ref(null);
const newPipelineRef = ref(null);
const taskDialogRef = ref(null);
const showMetrics = ref(false);
const agentFilter = ref('');
const inboxFilter = ref('');
const searchQuery = ref('');
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
// Someone looking for one patient knows the name or the number, not which stage
// the card sits in, so the search runs across the whole board at once.
const matchesSearch = task => {
  const term = searchQuery.value.trim().toLowerCase();
  if (!term) return true;

  return [
    task.title,
    task.contact?.name,
    task.contact?.phone_number,
    task.contact?.email,
  ].some(field => String(field || '').toLowerCase().includes(term));
};

const visibleTasks = stageId => {
  const filtered = tasksByStage.value(stageId).filter(task => {
    if (agentFilter.value && task.assigned_agent?.id !== agentFilter.value) {
      return false;
    }
    if (inboxFilter.value && task.inbox_id !== inboxFilter.value) return false;
    return matchesSearch(task);
  });

  return sortTasks(filtered, sortBy.value);
};

const visibleTaskList = computed(() =>
  stages.value.flatMap(stage => visibleTasks(stage.id))
);

const visibleCount = computed(() => visibleTaskList.value.length);

// The strip reports what is on screen, not what is in the database: with a filter
// on, a total that ignored it would describe a board nobody is looking at.
const stats = computed(() => boardStats(visibleTaskList.value));

const totalValue = computed(() =>
  formatMoney(stats.value.valueCents, locale.value)
);

const isFiltered = computed(
  () => !!(agentFilter.value || inboxFilter.value || searchQuery.value.trim())
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
      class="relative z-20 flex flex-wrap items-center gap-2 px-4 py-2.5 flex-shrink-0 border-b border-n-weak"
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

      <!-- Creating a funnel belongs next to the funnel switcher, not among the
           actions that operate on the board currently open. -->
      <Button
        v-if="isAdmin"
        variant="ghost"
        color="slate"
        size="sm"
        icon="i-lucide-plus"
        :title="t('KANBAN.BOARD.NEW_PIPELINE')"
        :aria-label="t('KANBAN.BOARD.NEW_PIPELINE')"
        @click="newPipelineRef?.open()"
      />

      <div class="flex flex-wrap items-center gap-2 ml-auto">
        <!-- The box is drawn by the wrapper and the input is stripped bare. The
             app's form reset outranks utilities on an input through a long :not()
             chain — it was taking the height, the padding, the border and a 16px
             bottom margin — and neutralising the input once beats bang-modifying
             every property it touches. -->
        <div
          class="flex items-center h-8 gap-1.5 px-2.5 border rounded-lg w-36 lg:w-56 bg-n-alpha-1 border-n-weak focus-within:border-n-brand"
        >
          <Icon
            icon="i-lucide-search"
            class="flex-shrink-0 size-3.5 text-n-slate-10"
          />
          <input
            v-model="searchQuery"
            type="search"
            :placeholder="t('KANBAN.FILTERS.SEARCH_PLACEHOLDER')"
            :aria-label="t('KANBAN.FILTERS.SEARCH')"
            class="w-full min-w-0 bg-transparent border-0 !h-auto !p-0 !m-0 !text-xs !shadow-none !rounded-none text-n-slate-12 placeholder:text-n-slate-10 focus:!outline-none focus:!shadow-none"
          />
        </div>

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
          :title="t('KANBAN.BOARD.SETTINGS')"
          :aria-label="t('KANBAN.BOARD.SETTINGS')"
          @click="settingsRef?.open()"
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

    <!-- What is late, what is due today, and how much money is on the board. It
         reads the cards already loaded, so it adds no request of its own. -->
    <div
      v-if="stages.length && visibleCount"
      class="flex flex-wrap items-center flex-shrink-0 px-4 py-1.5 gap-x-5 gap-y-1 text-[11px] border-b border-n-weak bg-n-solid-1 text-n-slate-11"
    >
      <span v-if="stats.onTimeRate !== null" class="flex items-center gap-1.5">
        <span class="rounded-full size-1.5 bg-n-teal-9" />
        {{ t('KANBAN.STATS.ON_TIME') }}
        <strong class="font-semibold text-n-slate-12 tabular-nums">
          {{ stats.onTimeRate }}%
        </strong>
      </span>
      <span class="flex items-center gap-1.5">
        <span class="rounded-full size-1.5 bg-n-amber-9" />
        {{ t('KANBAN.STATS.DUE_TODAY') }}
        <strong class="font-semibold text-n-slate-12 tabular-nums">
          {{ stats.dueToday }}
        </strong>
      </span>
      <span class="flex items-center gap-1.5">
        <span class="rounded-full size-1.5 bg-n-ruby-9" />
        {{ t('KANBAN.STATS.OVERDUE') }}
        <strong class="font-semibold text-n-slate-12 tabular-nums">
          {{ stats.overdue }}
        </strong>
      </span>
      <span
        v-if="totalValue"
        class="flex items-center gap-1.5 ltr:ml-auto rtl:mr-auto"
      >
        {{ t('KANBAN.STATS.TOTAL_VALUE') }}
        <strong class="font-semibold text-n-teal-11 tabular-nums">
          {{ totalValue }}
        </strong>
      </span>
    </div>

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
