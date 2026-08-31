<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  PRIORITY_STYLES,
  CHANNEL_ICONS,
  DEFAULT_CHANNEL_ICON,
  SLA_STYLES,
  slaStateFor,
} from '../constants';

const props = defineProps({
  task: { type: Object, required: true },
  stageColor: { type: String, default: '#4A86E8' },
});

defineEmits(['open']);

const { t } = useI18n();

const contactName = computed(
  () => props.task.contact?.name || t('KANBAN.CARD.UNKNOWN_CONTACT')
);

const channelIcon = computed(
  () => CHANNEL_ICONS[props.task.channel_type] || DEFAULT_CHANNEL_ICON
);

const priority = computed(
  () => PRIORITY_STYLES[props.task.priority] || PRIORITY_STYLES.medium
);

const slaState = computed(() => slaStateFor(props.task.due_date));
const slaClass = computed(() => SLA_STYLES[slaState.value] || '');

const timeInStage = computed(() => {
  const enteredAt = new Date(props.task.stage_entered_at);
  const minutes = Math.floor((Date.now() - enteredAt.getTime()) / 60000);
  if (minutes < 60) return t('KANBAN.CARD.TIME_MINUTES', { count: minutes });
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return t('KANBAN.CARD.TIME_HOURS', { count: hours });
  return t('KANBAN.CARD.TIME_DAYS', { count: Math.floor(hours / 24) });
});
</script>

<template>
  <div
    class="flex flex-col gap-2 p-2.5 bg-n-solid-1 border border-n-weak rounded-lg shadow-sm cursor-pointer hover:border-n-slate-6 hover:shadow transition-shadow"
    :style="{ borderLeftWidth: '3px', borderLeftColor: stageColor }"
    tabindex="0"
    @click="$emit('open', task)"
    @keydown.enter="$emit('open', task)"
  >
    <div class="flex items-center gap-1.5">
      <Icon :icon="channelIcon" class="flex-shrink-0 text-n-slate-10 size-3" />
      <span class="flex-1 min-w-0 text-sm font-medium truncate text-n-slate-12">
        {{ contactName }}
      </span>
      <Avatar
        v-if="task.assigned_agent"
        :name="task.assigned_agent.name"
        :src="task.assigned_agent.thumbnail"
        :size="18"
        rounded-full
      />
    </div>

    <p class="m-0 text-xs leading-snug text-n-slate-11 line-clamp-2">
      {{ task.title }}
    </p>

    <div class="flex items-center justify-between gap-2">
      <span
        class="px-1.5 py-0.5 rounded-full text-[10px] leading-none font-medium"
        :class="priority.class"
      >
        {{ t(priority.label) }}
      </span>
      <div class="flex items-center gap-2">
        <span
          v-if="slaState"
          class="flex items-center gap-1 text-[10px]"
          :class="slaClass"
        >
          <Icon icon="i-lucide-alarm-clock" class="size-3" />
        </span>
        <span class="flex items-center gap-1 text-[10px] text-n-slate-10 tabular-nums">
          <Icon icon="i-lucide-clock" class="size-3" />
          {{ timeInStage }}
        </span>
      </div>
    </div>
  </div>
</template>
