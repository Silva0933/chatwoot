<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  stage: { type: Object, required: true },
  taskCount: { type: Number, default: 0 },
  disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['update', 'delete']);

const { t } = useI18n();

const name = ref(props.stage.name);

watch(
  () => props.stage.name,
  value => {
    name.value = value;
  }
);

const kind = computed(() => {
  if (props.stage.is_won_stage) return 'won';
  if (props.stage.is_lost_stage) return 'lost';
  return 'open';
});

const commitName = () => {
  const trimmed = name.value.trim();
  if (!trimmed || trimmed === props.stage.name) {
    name.value = props.stage.name;
    return;
  }
  emit('update', { name: trimmed });
};

const onColorChange = event => emit('update', { color_hex: event.target.value });

// The three kinds are mutually exclusive, so picking one always clears the other
// two rather than leaving the server to reconcile a half-set pair of booleans.
const setKind = next => {
  if (next === kind.value) return;
  emit('update', {
    is_won_stage: next === 'won',
    is_lost_stage: next === 'lost',
  });
};

const KIND_OPTIONS = [
  { value: 'open', icon: 'i-lucide-circle-dot', labelKey: 'KANBAN.SETTINGS.KIND.OPEN' },
  { value: 'won', icon: 'i-lucide-circle-check-big', labelKey: 'KANBAN.SETTINGS.KIND.WON' },
  { value: 'lost', icon: 'i-lucide-circle-x', labelKey: 'KANBAN.SETTINGS.KIND.LOST' },
];
</script>

<template>
  <div
    class="flex items-center gap-2 px-2 py-2 border rounded-lg border-n-weak bg-n-solid-1"
  >
    <Icon
      icon="i-lucide-grip-vertical"
      class="flex-shrink-0 cursor-grab size-4 text-n-slate-9 drag-handle"
    />

    <label class="relative flex-shrink-0 size-5">
      <span class="sr-only">{{ t('KANBAN.SETTINGS.STAGE_COLOR') }}</span>
      <input
        type="color"
        :value="stage.color_hex"
        :disabled="disabled"
        class="w-full h-full p-0 border rounded cursor-pointer border-n-weak bg-transparent"
        @change="onColorChange"
      />
    </label>

    <input
      v-model="name"
      type="text"
      :disabled="disabled"
      class="flex-1 min-w-0 px-2 py-1 text-sm bg-transparent border rounded-md border-transparent text-n-slate-12 hover:border-n-weak focus:border-n-brand focus:outline-none"
      @blur="commitName"
      @keyup.enter="commitName"
    />

    <span
      class="px-1.5 py-0.5 flex-shrink-0 rounded-full text-xs leading-none bg-n-solid-3 text-n-slate-11 tabular-nums"
    >
      {{ taskCount }}
    </span>

    <div class="flex items-center flex-shrink-0 gap-0.5 p-0.5 rounded-md bg-n-solid-3">
      <button
        v-for="option in KIND_OPTIONS"
        :key="option.value"
        type="button"
        :disabled="disabled"
        :title="t(option.labelKey)"
        :aria-label="t(option.labelKey)"
        :aria-pressed="kind === option.value"
        class="flex items-center justify-center rounded size-6 transition-colors"
        :class="
          kind === option.value
            ? 'bg-n-solid-1 text-n-slate-12 shadow-sm'
            : 'text-n-slate-10 hover:text-n-slate-12'
        "
        @click="setKind(option.value)"
      >
        <Icon :icon="option.icon" class="size-3.5" />
      </button>
    </div>

    <Button
      variant="faded"
      color="ruby"
      size="xs"
      icon="i-lucide-trash-2"
      :disabled="disabled"
      :aria-label="t('KANBAN.SETTINGS.DELETE_STAGE')"
      @click="emit('delete')"
    />
  </div>
</template>
