<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  pipelines: { type: Array, default: () => [] },
  activePipelineId: { type: [Number, String], default: null },
});

defineEmits(['select']);
</script>

<template>
  <div
    v-if="pipelines.length > 1"
    class="flex items-center gap-0.5 p-0.5 rounded-lg bg-n-solid-2 border border-n-weak"
  >
    <button
      v-for="pipeline in pipelines"
      :key="pipeline.id"
      type="button"
      class="flex items-center gap-1.5 px-2.5 h-7 text-xs rounded-md transition-colors"
      :class="
        pipeline.id === activePipelineId
          ? 'bg-n-alpha-1 dark:bg-n-solid-active text-n-slate-12 font-medium shadow-sm'
          : 'text-n-slate-11 hover:text-n-slate-12'
      "
      @click="$emit('select', pipeline.id)"
    >
      <Icon icon="i-lucide-columns-3" class="size-3" />
      {{ pipeline.name }}
    </button>
  </div>
</template>
