<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  pipelines: { type: Array, default: () => [] },
  activePipelineId: { type: [Number, String], default: null },
});

defineEmits(['select']);
</script>

<template>
  <div v-if="pipelines.length > 1" class="flex items-center gap-1">
    <button
      v-for="pipeline in pipelines"
      :key="pipeline.id"
      class="flex items-center gap-1.5 px-2.5 py-1 text-xs rounded-md border transition-colors"
      :class="
        pipeline.id === activePipelineId
          ? 'bg-n-solid-3 border-n-strong text-n-slate-12'
          : 'bg-transparent border-n-weak text-n-slate-11 hover:text-n-slate-12'
      "
      @click="$emit('select', pipeline.id)"
    >
      <Icon icon="i-lucide-columns-3" class="size-3" />
      {{ pipeline.name }}
    </button>
  </div>
</template>
