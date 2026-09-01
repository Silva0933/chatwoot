<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownContainer from 'dashboard/components-next/dropdown-menu/base/DropdownContainer.vue';
import DropdownBody from 'dashboard/components-next/dropdown-menu/base/DropdownBody.vue';
import DropdownSection from 'dashboard/components-next/dropdown-menu/base/DropdownSection.vue';
import DropdownItem from 'dashboard/components-next/dropdown-menu/base/DropdownItem.vue';
import {
  CHANNEL_ICONS,
  DEFAULT_CHANNEL_ICON,
  CHANNEL_META,
  DEFAULT_CHANNEL_META,
  PRIORITY_GLYPHS,
  PRIORITY_SPINE,
  DEFAULT_PRIORITY_SPINE,
  SLA_STATE,
  SLA_PILL,
  slaStateFor,
  formatDueDate,
  formatMoney,
} from '../constants';

const props = defineProps({
  task: { type: Object, required: true },
});

const emit = defineEmits(['open', 'edit']);

const { t, locale } = useI18n();

const contactName = computed(
  () => props.task.contact?.name || t('KANBAN.CARD.UNKNOWN_CONTACT')
);

// Phone first, e-mail as the fallback: on a WhatsApp funnel the number is what
// someone actually recognises a patient by.
const contactHandle = computed(
  () => props.task.contact?.phone_number || props.task.contact?.email || null
);

// What the card is about, in order of how deliberate it is: a summary someone
// wrote, then a title that says more than the contact's name (cards opened from a
// conversation are titled after the contact, and printing that twice says
// nothing), then the conversation's last message. The message is marked as such
// so nobody reads a patient's own words as a note the clinic wrote.
const summary = computed(() => {
  const written = props.task.summary?.trim();
  if (written) return { text: written, fromMessage: false };

  if (props.task.title && props.task.title !== props.task.contact?.name) {
    return { text: props.task.title, fromMessage: false };
  }

  return props.task.last_message
    ? { text: props.task.last_message, fromMessage: true }
    : null;
});

const channel = computed(
  () => CHANNEL_META[props.task.channel_type] || DEFAULT_CHANNEL_META
);

const channelIcon = computed(
  () => CHANNEL_ICONS[props.task.channel_type] || DEFAULT_CHANNEL_ICON
);

const priority = computed(
  () => PRIORITY_GLYPHS[props.task.priority] || PRIORITY_GLYPHS.medium
);

const spine = computed(
  () => PRIORITY_SPINE[props.task.priority] || DEFAULT_PRIORITY_SPINE
);

// Read through the same fallback as the glyph. Calling toUpperCase on the raw
// field in the template would throw on a card without one, and a TypeError in a
// child template takes the whole board down with it.
const priorityLabel = computed(() =>
  t(`KANBAN.PRIORITY.${(props.task.priority || 'medium').toUpperCase()}`)
);

const slaState = computed(() => slaStateFor(props.task.due_date));

const slaPill = computed(
  () => SLA_PILL[slaState.value] || SLA_PILL[SLA_STATE.ON_TRACK]
);

const dealValue = computed(() =>
  formatMoney(props.task.value_cents, locale.value)
);

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
    class="relative flex flex-col gap-2.5 p-3 border border-l-[3px] rounded-xl cursor-pointer group bg-n-solid-2 border-n-weak hover:bg-n-solid-3 hover:border-n-slate-6 transition-colors"
    :class="spine"
    tabindex="0"
    @click="emit('open', task)"
    @keydown.enter="emit('open', task)"
  >
    <div class="flex items-start gap-2.5">
      <span class="relative flex-shrink-0">
        <Avatar
          :name="contactName"
          :src="task.contact?.thumbnail"
          :size="30"
          rounded-full
        />
        <span
          class="absolute flex items-center justify-center rounded-full -bottom-0.5 -right-0.5 size-3.5 bg-n-solid-2 ring-2 ring-n-solid-2"
          :style="{ color: channel.dot }"
          :title="channel.label"
        >
          <Icon :icon="channelIcon" class="size-2.5" />
        </span>
      </span>

      <div class="flex-1 min-w-0">
        <h4
          class="m-0 text-[13px] font-semibold leading-tight truncate text-n-slate-12"
        >
          {{ contactName }}
        </h4>
        <p
          v-if="contactHandle"
          class="m-0 mt-0.5 text-[10px] leading-tight truncate text-n-slate-10 tabular-nums"
        >
          {{ contactHandle }}
        </p>
      </div>

      <DropdownContainer class="flex-shrink-0 !space-y-0" @click.stop>
        <template #trigger="{ toggle, isOpen }">
          <button
            type="button"
            class="flex items-center justify-center transition-opacity rounded-md size-6 text-n-slate-10 hover:text-n-slate-12 hover:bg-n-alpha-2 opacity-0 group-hover:opacity-100 focus:opacity-100"
            :class="{ '!opacity-100': isOpen }"
            :aria-label="t('KANBAN.CARD.ACTIONS')"
            aria-haspopup="menu"
            :aria-expanded="isOpen"
            @click="toggle"
          >
            <Icon icon="i-lucide-ellipsis" class="size-4" />
          </button>
        </template>
        <DropdownBody class="z-50 mt-1 min-w-44">
          <DropdownSection>
            <DropdownItem
              :label="t('KANBAN.TASK.EDIT_TITLE')"
              icon="i-lucide-pencil"
              :click="() => emit('edit', task)"
            />
            <DropdownItem
              v-if="task.conversation_id"
              :label="t('KANBAN.CARD.OPEN_CONVERSATION')"
              icon="i-lucide-message-square"
              :click="() => emit('open', task)"
            />
          </DropdownSection>
        </DropdownBody>
      </DropdownContainer>
    </div>

    <p
      v-if="summary"
      class="m-0 text-xs leading-relaxed line-clamp-2"
      :class="summary.fromMessage ? 'italic text-n-slate-10' : 'text-n-slate-11'"
    >
      {{ summary.text }}
    </p>

    <div class="flex items-center justify-between gap-2">
      <span
        class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-n-alpha-1 text-[11px] leading-none text-n-slate-11"
      >
        <span
          class="rounded-full size-1.5"
          :style="{ backgroundColor: channel.dot }"
        />
        {{ channel.label }}
      </span>
      <span
        v-if="dealValue"
        class="text-[13px] font-semibold leading-none tabular-nums text-n-teal-11"
      >
        {{ dealValue }}
      </span>
    </div>

    <div
      class="flex items-center justify-between gap-2 pt-2.5 border-t border-n-weak"
    >
      <div class="flex items-center min-w-0 gap-2">
        <Icon
          :icon="priority.icon"
          class="flex-shrink-0 size-4"
          :class="priority.class"
          :title="priorityLabel"
        />
        <span
          v-if="dueLabel"
          class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] leading-none tabular-nums"
          :class="slaPill"
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
      </div>

      <div class="flex items-center flex-shrink-0 gap-2">
        <span
          class="flex items-center gap-1 text-[10px] leading-none text-n-slate-10 tabular-nums"
          :title="t('KANBAN.CARD.TIME_IN_STAGE')"
        >
          <Icon icon="i-lucide-clock" class="size-3" />
          {{ timeInStage }}
        </span>
        <Avatar
          v-if="task.assigned_agent"
          :name="task.assigned_agent.name"
          :src="task.assigned_agent.thumbnail"
          :size="22"
          rounded-full
        />
        <span
          v-else
          class="flex items-center justify-center border border-dashed rounded-full size-[22px] border-n-slate-6 text-n-slate-9"
          :title="t('KANBAN.TASK.UNASSIGNED')"
        >
          <Icon icon="i-lucide-user" class="size-3" />
        </span>
      </div>
    </div>
  </div>
</template>
