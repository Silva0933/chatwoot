<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PipelineCard from './PipelineCard.vue';

const props = defineProps({
  stage: { type: Object, required: true },
  conversations: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  isDragOver: { type: Boolean, default: false },
  draggingId: { type: [Number, String], default: null },
});

const emit = defineEmits([
  'card-dragstart',
  'card-dragend',
  'card-click',
  'dragover',
  'dragleave',
  'drop',
]);
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 w-[272px] rounded-xl border border-n-weak bg-n-solid-2/60"
  >
    <div class="flex flex-col gap-2 px-3 pt-3 pb-2.5 border-b border-n-weak">
      <div class="flex items-center gap-2">
        <span
          class="flex items-center justify-center rounded-md size-5"
          :style="{ backgroundColor: `${stage.color}26`, color: stage.color }"
        >
          <Icon :icon="stage.icon" class="size-3" />
        </span>
        <h3 class="flex-1 min-w-0 m-0 text-sm font-medium truncate text-n-slate-12">
          {{ stage.name }}
        </h3>
        <span
          class="px-1.5 py-0.5 rounded-full text-xs leading-none bg-n-solid-3 text-n-slate-11 tabular-nums"
        >
          {{ conversations.length }}
        </span>
      </div>
    </div>

    <div
      class="flex flex-col flex-1 min-h-[120px] gap-2 p-2 overflow-y-auto max-h-[calc(100vh-220px)] rounded-b-xl transition-colors"
      :class="isDragOver ? 'bg-n-solid-blue/40 outline-dashed outline-1 -outline-offset-4 outline-n-brand' : ''"
      @dragover.prevent="$emit('dragover')"
      @dragleave="$emit('dragleave')"
      @drop.prevent="$emit('drop')"
    >
      <div
        v-if="isLoading"
        class="flex items-center justify-center flex-1 py-6"
      >
        <Spinner />
      </div>
      <p
        v-else-if="!conversations.length"
        class="py-6 text-xs italic text-center text-n-slate-9"
      >
        Nenhuma conversa aqui
      </p>
      <PipelineCard
        v-for="conversation in conversations"
        :key="conversation.id"
        :conversation="conversation"
        :stage-color="stage.color"
        :dragging="draggingId === conversation.id"
        @dragstart="emit('card-dragstart', conversation)"
        @dragend="emit('card-dragend')"
        @click="emit('card-click', conversation)"
      />
    </div>
  </div>
</template>
