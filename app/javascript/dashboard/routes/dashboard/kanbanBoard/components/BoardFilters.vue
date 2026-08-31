<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { SORT_OPTIONS } from '../constants';

const props = defineProps({
  tasks: { type: Array, default: () => [] },
});

const agentId = defineModel('agentId', { type: [Number, String], default: '' });
const inboxId = defineModel('inboxId', { type: [Number, String], default: '' });
const sortBy = defineModel('sortBy', { type: String, default: 'position' });

const { t } = useI18n();

const openMenu = ref(null);

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

const selectedSort = computed(
  () => SORT_OPTIONS.find(option => option.value === sortBy.value) || SORT_OPTIONS[0]
);

const menus = computed(() => [
  {
    key: 'agent',
    icon: 'i-lucide-user-round',
    label:
      presentAgents.value.find(agent => agent.id === agentId.value)?.name ||
      t('KANBAN.FILTERS.ALL_AGENTS'),
    isActive: !!agentId.value,
    sections: [
      {
        label: t('KANBAN.FILTERS.AGENT'),
        options: [
          {
            label: t('KANBAN.FILTERS.ALL_AGENTS'),
            value: '',
            action: 'agent',
            isSelected: !agentId.value,
          },
          ...presentAgents.value.map(agent => ({
            label: agent.name,
            value: agent.id,
            action: 'agent',
            thumbnail: { name: agent.name, src: agent.thumbnail },
            isSelected: agentId.value === agent.id,
          })),
        ],
      },
    ],
  },
  {
    key: 'inbox',
    icon: 'i-lucide-inbox',
    label:
      presentInboxes.value.find(inbox => inbox.id === inboxId.value)?.name ||
      t('KANBAN.FILTERS.ALL_INBOXES'),
    isActive: !!inboxId.value,
    sections: [
      {
        label: t('KANBAN.FILTERS.INBOX'),
        options: [
          {
            label: t('KANBAN.FILTERS.ALL_INBOXES'),
            value: '',
            action: 'inbox',
            isSelected: !inboxId.value,
          },
          ...presentInboxes.value.map(inbox => ({
            label: inbox.name,
            value: inbox.id,
            action: 'inbox',
            isSelected: inboxId.value === inbox.id,
          })),
        ],
      },
    ],
  },
  {
    key: 'sort',
    icon: 'i-lucide-arrow-up-down',
    label: t(selectedSort.value.labelKey),
    isActive: sortBy.value !== SORT_OPTIONS[0].value,
    sections: [
      {
        label: t('KANBAN.FILTERS.SORT'),
        options: SORT_OPTIONS.map(option => ({
          label: t(option.labelKey),
          value: option.value,
          action: 'sort',
          isSelected: sortBy.value === option.value,
        })),
      },
    ],
  },
]);

const toggleMenu = key => {
  openMenu.value = openMenu.value === key ? null : key;
};

const closeMenu = () => {
  openMenu.value = null;
};

const onAction = ({ action, value }) => {
  if (action === 'agent') agentId.value = value;
  if (action === 'inbox') inboxId.value = value;
  if (action === 'sort') sortBy.value = value;
  openMenu.value = null;
};
</script>

<template>
  <div v-on-click-outside="closeMenu" class="flex items-center gap-2">
    <div v-for="menu in menus" :key="menu.key" class="relative">
      <Button
        :icon="menu.icon"
        :color="menu.isActive ? 'blue' : 'slate'"
        variant="faded"
        size="sm"
        :class="{ 'bg-n-slate-9/10': openMenu === menu.key }"
        @click="toggleMenu(menu.key)"
      >
        <span class="min-w-0 max-w-[140px] truncate">{{ menu.label }}</span>
        <Icon icon="i-lucide-chevron-down" class="shrink-0 size-3.5" />
      </Button>
      <DropdownMenu
        v-if="openMenu === menu.key"
        :menu-sections="menu.sections"
        class="mt-2 min-w-52 max-h-80 top-full ltr:start-0 rtl:end-0"
        @action="onAction"
      />
    </div>
  </div>
</template>
