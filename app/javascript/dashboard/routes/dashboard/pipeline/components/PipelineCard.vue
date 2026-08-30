<script setup>
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  conversation: { type: Object, required: true },
  stageColor: { type: String, required: true },
  dragging: { type: Boolean, default: false },
});

defineEmits(['dragstart', 'dragend', 'click']);

const { getPlainText } = useMessageFormatter();

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee || null);

const channelIcon = computed(() => {
  const channel = props.conversation.meta?.channel || '';
  if (channel.includes('WebWidget')) return 'i-lucide-globe';
  if (channel.includes('Whatsapp')) return 'i-lucide-message-circle';
  if (channel.includes('Email')) return 'i-lucide-mail';
  if (channel.includes('Api')) return 'i-lucide-webhook';
  return 'i-lucide-inbox';
});

const previewText = computed(() => {
  const raw = props.conversation.last_non_activity_message?.content;
  if (!raw) return '(sem mensagens de texto)';
  return getPlainText(raw);
});

const otherLabels = computed(() =>
  (props.conversation.labels || []).filter(
    label => label !== props.conversation.__stageLabel
  )
);
</script>

<template>
  <div
    class="flex flex-col gap-1.5 p-2.5 bg-n-solid-1 border border-n-weak rounded-lg shadow-sm cursor-grab active:cursor-grabbing hover:border-n-slate-6 hover:shadow transition-shadow"
    :class="{ 'opacity-40': dragging }"
    draggable="true"
    tabindex="0"
    @dragstart="$emit('dragstart', $event)"
    @dragend="$emit('dragend', $event)"
    @click="$emit('click')"
  >
    <div class="flex items-center gap-1.5">
      <Icon :icon="channelIcon" class="flex-shrink-0 text-n-slate-10 size-3" />
      <span
        class="flex-1 min-w-0 text-sm font-medium truncate text-n-slate-12"
      >
        {{ contact.name || 'Contato sem nome' }}
      </span>
      <Avatar
        v-if="assignee"
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="18"
        rounded-full
      />
    </div>

    <p class="m-0 text-xs leading-snug text-n-slate-11 line-clamp-2">
      {{ previewText }}
    </p>

    <div class="flex items-center justify-between gap-2">
      <TimeAgo
        :last-activity-timestamp="conversation.timestamp"
        :created-at-timestamp="conversation.created_at"
        :is-auto-refresh-enabled="false"
        class="!ml-0 text-xxs"
      />
      <div v-if="otherLabels.length" class="flex flex-wrap justify-end gap-1">
        <span
          v-for="label in otherLabels"
          :key="label"
          class="px-1.5 py-0.5 rounded-full text-[10px] leading-none bg-n-slate-3 text-n-slate-11"
        >
          {{ label }}
        </span>
      </div>
    </div>

    <div
      class="h-[3px] -mx-2.5 -mb-2.5 mt-0.5 rounded-b-lg"
      :style="{ backgroundColor: stageColor }"
    />
  </div>
</template>
