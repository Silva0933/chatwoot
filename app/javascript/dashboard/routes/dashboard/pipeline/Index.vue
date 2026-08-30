<script setup>
import { onMounted, reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store.js';
import { useAlert } from 'dashboard/composables';
import ConversationApi from 'dashboard/api/inbox/conversation';
import ConversationLabelsApi from 'dashboard/api/conversations';
import { PIPELINE_STAGES } from './constants';
import PipelineColumn from './components/PipelineColumn.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();

const accountId = route.params.accountId;

const columns = reactive(
  Object.fromEntries(
    PIPELINE_STAGES.map(stage => [
      stage.labelTitle,
      { conversations: [], isLoading: true },
    ])
  )
);

const draggingConversation = ref(null);
const dragOverStage = ref(null);
const isBootstrapping = ref(true);

const ensureStageLabels = async () => {
  await store.dispatch('labels/get');
  const existingTitles = store.getters['labels/getLabels'].map(l => l.title);
  const missing = PIPELINE_STAGES.filter(
    stage => !existingTitles.includes(stage.labelTitle)
  );
  // Sequential on purpose: Chatwoot's create-label validation isn't safe
  // to fire concurrently against the same account without risking duplicates.
  for (const stage of missing) {
    // eslint-disable-next-line no-await-in-loop
    await store.dispatch('labels/create', {
      title: stage.labelTitle,
      description: `Estágio do pipeline: ${stage.name}`,
      color: stage.color,
      show_on_sidebar: false,
    });
  }
};

const fetchColumn = async stage => {
  columns[stage.labelTitle].isLoading = true;
  try {
    const res = await ConversationApi.get({
      labels: [stage.labelTitle],
      status: 'all',
    });
    columns[stage.labelTitle].conversations = res.data.data.payload.map(
      conversation => ({ ...conversation, __stageLabel: stage.labelTitle })
    );
  } catch (error) {
    useAlert('Não foi possível carregar as conversas dessa coluna.');
  } finally {
    columns[stage.labelTitle].isLoading = false;
  }
};

const fetchAllColumns = () =>
  Promise.all(PIPELINE_STAGES.map(fetchColumn));

onMounted(async () => {
  try {
    await ensureStageLabels();
    await fetchAllColumns();
  } finally {
    isBootstrapping.value = false;
  }
});

const onCardDragStart = conversation => {
  draggingConversation.value = conversation;
};

const onCardDragEnd = () => {
  draggingConversation.value = null;
  dragOverStage.value = null;
};

const onColumnDragOver = stage => {
  dragOverStage.value = stage.labelTitle;
};

const onColumnDragLeave = () => {
  dragOverStage.value = null;
};

const onColumnDrop = async targetStage => {
  const conversation = draggingConversation.value;
  dragOverStage.value = null;
  draggingConversation.value = null;
  if (!conversation) return;
  if (conversation.__stageLabel === targetStage.labelTitle) return;

  const nextLabels = conversation.labels
    .filter(
      label => !PIPELINE_STAGES.some(stage => stage.labelTitle === label)
    )
    .concat(targetStage.labelTitle);

  // Optimistic move so the drag feels instant; re-synced from the server below.
  const sourceColumn = columns[conversation.__stageLabel];
  sourceColumn.conversations = sourceColumn.conversations.filter(
    c => c.id !== conversation.id
  );
  columns[targetStage.labelTitle].conversations.unshift({
    ...conversation,
    labels: nextLabels,
    __stageLabel: targetStage.labelTitle,
  });

  try {
    await ConversationLabelsApi.updateLabels(conversation.id, nextLabels);
  } catch (error) {
    useAlert('Não foi possível mover essa conversa. Revertendo.');
    await Promise.all([
      fetchColumn(
        PIPELINE_STAGES.find(s => s.labelTitle === conversation.__stageLabel)
      ),
      fetchColumn(targetStage),
    ]);
  }
};

const openConversation = conversation => {
  router.push({
    name: 'inbox_conversation',
    params: { accountId, conversation_id: conversation.id },
  });
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header class="flex-shrink-0 px-4 py-3 border-b border-n-weak">
      <h1 class="m-0 text-base font-medium text-n-slate-12">Pipeline</h1>
      <p class="m-0 text-xs text-n-slate-11">
        Arraste uma conversa entre as colunas para mudar o estágio de
        atendimento.
      </p>
    </header>

    <div class="flex flex-1 gap-3 p-3 overflow-x-auto">
      <PipelineColumn
        v-for="stage in PIPELINE_STAGES"
        :key="stage.labelTitle"
        :stage="stage"
        :conversations="columns[stage.labelTitle].conversations"
        :is-loading="isBootstrapping || columns[stage.labelTitle].isLoading"
        :is-drag-over="dragOverStage === stage.labelTitle"
        :dragging-id="draggingConversation?.id"
        @card-dragstart="onCardDragStart"
        @card-dragend="onCardDragEnd"
        @card-click="openConversation"
        @dragover="onColumnDragOver(stage)"
        @dragleave="onColumnDragLeave"
        @drop="onColumnDrop(stage)"
      />
    </div>
  </section>
</template>
