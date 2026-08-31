<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { SORT_OPTIONS } from '../constants';

const props = defineProps({
  tasks: { type: Array, default: () => [] },
});

const agentId = defineModel('agentId', { type: [Number, String], default: '' });
const inboxId = defineModel('inboxId', { type: [Number, String], default: '' });
const sortBy = defineModel('sortBy', { type: String, default: 'position' });

const { t } = useI18n();

const agents = useMapGetter('agents/getVerifiedAgents');
const inboxes = useMapGetter('inboxes/getInboxes');

// Only what the board actually holds is offered. A funnel fed by one inbox should
// not present a dropdown of twenty, and picking an empty filter reads as a bug.
const presentAgents = computed(() => {
  const ids = new Set(props.tasks.map(task => task.assigned_agent?.id));
  return agents.value.filter(agent => ids.has(agent.id));
});

const presentInboxes = computed(() => {
  const ids = new Set(props.tasks.map(task => task.inbox_id));
  return inboxes.value.filter(inbox => ids.has(inbox.id));
});

const onSelect = (model, value) => {
  model.value = value === '' ? '' : Number(value);
};
</script>

<template>
  <div class="flex items-center gap-2">
    <label
      class="flex items-center gap-1.5 pl-2 pr-1 rounded-lg h-8 border border-n-weak bg-n-solid-2 text-n-slate-11 focus-within:border-n-brand"
    >
      <Icon icon="i-lucide-user-round" class="size-3.5 text-n-slate-10" />
      <span class="sr-only">{{ t('KANBAN.FILTERS.AGENT') }}</span>
      <select
        :value="agentId"
        class="h-full pr-1 text-xs bg-transparent border-0 cursor-pointer text-n-slate-12 focus:outline-none"
        @change="onSelect(agentId, $event.target.value)"
      >
        <option value="">{{ t('KANBAN.FILTERS.ALL_AGENTS') }}</option>
        <option v-for="agent in presentAgents" :key="agent.id" :value="agent.id">
          {{ agent.name }}
        </option>
      </select>
    </label>

    <label
      class="flex items-center gap-1.5 pl-2 pr-1 rounded-lg h-8 border border-n-weak bg-n-solid-2 text-n-slate-11 focus-within:border-n-brand"
    >
      <Icon icon="i-lucide-inbox" class="size-3.5 text-n-slate-10" />
      <span class="sr-only">{{ t('KANBAN.FILTERS.INBOX') }}</span>
      <select
        :value="inboxId"
        class="h-full pr-1 text-xs bg-transparent border-0 cursor-pointer text-n-slate-12 focus:outline-none"
        @change="onSelect(inboxId, $event.target.value)"
      >
        <option value="">{{ t('KANBAN.FILTERS.ALL_INBOXES') }}</option>
        <option v-for="inbox in presentInboxes" :key="inbox.id" :value="inbox.id">
          {{ inbox.name }}
        </option>
      </select>
    </label>

    <label
      class="flex items-center gap-1.5 pl-2 pr-1 rounded-lg h-8 border border-n-weak bg-n-solid-2 text-n-slate-11 focus-within:border-n-brand"
    >
      <Icon icon="i-lucide-arrow-up-down" class="size-3.5 text-n-slate-10" />
      <span class="sr-only">{{ t('KANBAN.FILTERS.SORT') }}</span>
      <select
        v-model="sortBy"
        class="h-full pr-1 text-xs bg-transparent border-0 cursor-pointer text-n-slate-12 focus:outline-none"
      >
        <option v-for="option in SORT_OPTIONS" :key="option.value" :value="option.value">
          {{ t(option.labelKey) }}
        </option>
      </select>
    </label>
  </div>
</template>
