<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  CHANNEL_ICONS,
  DEFAULT_CHANNEL_ICON,
  CHANNEL_META,
  DEFAULT_CHANNEL_META,
  PRIORITY_GLYPHS,
  SLA_STATE,
  slaStateFor,
  formatDueDate,
} from '../constants';

const props = defineProps({
  task: { type: Object, required: true },
});

defineEmits(['open', 'edit']);

const { t, locale } = useI18n();

const contactName = computed(
  () => props.task.contact?.name || t('KANBAN.CARD.UNKNOWN_CONTACT')
);

const channel = computed(
  () => CHANNEL_META[props.task.channel_type] || DEFAULT_CHANNEL_META
);

const channelIcon = computed(
  () => CHANNEL_ICONS[props.task.channel_type] || DEFAULT_CHANNEL_ICON
);

const priority = computed(
  () => PRIORITY_GLYPHS[props.task.priority] || PRIORITY_GLYPHS.medium
);

const slaState = computed(() => slaStateFor(props.task.due_date));

// Only a due date that is close or past earns colour. Painting every date amber
// would leave nothing for the ones that actually need attention today.
const dueClass = computed(() => {
  if (slaState.value === SLA_STATE.OVERDUE) return 'text-n-ruby-11';
  if (slaState.value === SLA_STATE.DUE_TODAY) return 'text-n-amber-11';
  return 'text-n-slate-10';
});

const dueLabel = computed(() =>
  formatDueDate(props.task.due_date, t, locale.value)
);

const timeInStage = computed(() => {
  const minutes = Math.floor(
    (Date.now() - new Date(props.task.stage_entered_at).getTime()) / 60000
  );
  if (minutes < 60) return t('KANBAN.CARD.TIME_MINUTES', { count: minutes });

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return t('KANBAN.CARD.TIME_HOURS', { count: hours });

  return t('KANBAN.CARD.TIME_DAYS', { count: Math.floor(hours / 24) });
});
</script>

<template>
  <div
    class="group flex flex-col gap-2 p-3 rounded-xl cursor-pointer bg-n-solid-2 border border-n-weak hover:border-n-slate-7 transition-colors"
    tabindex="0"
    @click="$emit('open', task)"
    @keydown.enter="$emit('open', task)"
  >
    <div class="flex items-start gap-2">
      <h4 class="flex-1 min-w-0 m-0 text-sm font-medium truncate text-n-slate-12">
        {{ contactName }}
      </h4>
      <button
        type="button"
        class="flex-shrink-0 p-0.5 rounded opacity-0 group-hover:opacity-100 focus:opacity-100 text-n-slate-10 hover:text-n-slate-12 hover:bg-n-solid-3 transition-opacity"
        :aria-label="t('KANBAN.TASK.EDIT_TITLE')"
        @click.stop="$emit('edit', task)"
      >
        <Icon icon="i-lucide-pencil" class="size-3.5" />
      </button>
    </div>

    <div class="flex items-center justify-between gap-2">
      <span class="relative flex-shrink-0">
        <Avatar
          :name="contactName"
          :src="task.contact?.thumbnail"
          :size="26"
          rounded-full
        />
        <span
          class="absolute flex items-center justify-center rounded-full -bottom-0.5 -right-0.5 size-3.5 bg-n-solid-2 ring-2 ring-n-solid-2"
          :style="{ color: channel.dot }"
        >
          <Icon :icon="channelIcon" class="size-2.5" />
        </span>
      </span>

      <Avatar
        v-if="task.assigned_agent"
        :name="task.assigned_agent.name"
        :src="task.assigned_agent.thumbnail"
        :size="26"
        rounded-full
      />
      <span
        v-else
        class="flex items-center justify-center border border-dashed rounded-full size-[26px] border-n-slate-6 text-n-slate-9"
        :title="t('KANBAN.TASK.UNASSIGNED')"
      >
        <Icon icon="i-lucide-user" class="size-3" />
      </span>
    </div>

    <span
      class="inline-flex items-center self-start gap-1.5 px-2 py-0.5 rounded-md bg-n-solid-3 text-[11px] leading-none text-n-slate-11"
    >
      <span
        class="rounded-full size-1.5"
        :style="{ backgroundColor: channel.dot }"
      />
      {{ channel.label }}
    </span>

    <div class="flex items-center justify-between gap-2 pt-0.5">
      <Icon
        :icon="priority.icon"
        class="flex-shrink-0 size-4"
        :class="priority.class"
        :title="t(`KANBAN.PRIORITY.${task.priority.toUpperCase()}`)"
      />

      <div class="flex items-center gap-2.5 text-[11px] leading-none">
        <span
          v-if="dueLabel"
          class="flex items-center gap-1 tabular-nums"
          :class="dueClass"
        >
          <Icon
            :icon="
              slaState === SLA_STATE.ON_TRACK
                ? 'i-lucide-calendar'
                : 'i-lucide-alarm-clock'
            "
            class="size-3"
          />
          {{ dueLabel }}
        </span>
        <span class="flex items-center gap-1 text-n-slate-10 tabular-nums">
          <Icon icon="i-lucide-clock" class="size-3" />
          {{ timeInStage }}
        </span>
      </div>
    </div>
  </div>
</template>
