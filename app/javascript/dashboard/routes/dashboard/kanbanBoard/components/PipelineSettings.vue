<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import StageRow from './StageRow.vue';
import { AUTOMATION_FLAGS } from '../constants';

const props = defineProps({
  pipeline: { type: Object, required: true },
});

const emit = defineEmits(['deleted']);

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const newStageName = ref('');
const stagePendingDeletion = ref(null);
const fallbackStageId = ref(null);

const inboxes = useMapGetter('inboxes/getInboxes');
const agents = useMapGetter('agents/getVerifiedAgents');
const members = useMapGetter('kanban/getMembers');
const uiFlags = useMapGetter('kanban/getUIFlags');
const taskCountByStage = useMapGetter('kanban/getTaskCountByStage');

const isSaving = computed(() => uiFlags.value.isSavingSettings);
const stages = computed(() => props.pipeline.stages || []);
const automation = computed(() => props.pipeline.automation || {});
const targetInboxIds = computed(() => automation.value.target_inbox_ids || []);

const dispatch = async (action, payload) => {
  try {
    await store.dispatch(`kanban/${action}`, {
      pipelineId: props.pipeline.id,
      ...payload,
    });
  } catch (error) {
    useAlert(error?.response?.data?.error || t('KANBAN.SETTINGS.SAVE_ERROR'));
  }
};

// vuedraggable writes back into the bound array; the pipeline comes from the store,
// so the reorder is reported to the server and the refetched pipeline is what wins.
const draggableStages = computed({
  get: () => stages.value,
  set: value => {
    dispatch('reorderStages', { stageIds: value.map(stage => stage.id) });
  },
});

const onAddStage = async () => {
  const name = newStageName.value.trim();
  if (!name) return;
  newStageName.value = '';
  await dispatch('createStage', { name });
};

const onRequestDelete = stage => {
  stagePendingDeletion.value = stage;
  fallbackStageId.value =
    stages.value.find(other => other.id !== stage.id)?.id ?? null;
};

const onConfirmDelete = async () => {
  const stage = stagePendingDeletion.value;
  stagePendingDeletion.value = null;
  await dispatch('deleteStage', {
    id: stage.id,
    moveTasksToStageId: fallbackStageId.value,
  });
};

const onToggleAutomation = (key, value) => {
  dispatch('updateAutomation', { [key]: value });
};

const onToggleInbox = inboxId => {
  const current = targetInboxIds.value;
  const next = current.includes(inboxId)
    ? current.filter(id => id !== inboxId)
    : [...current, inboxId];
  dispatch('updateAutomation', { target_inbox_ids: next });
};

const onDeletePipeline = async () => {
  try {
    await store.dispatch('kanban/deletePipeline', props.pipeline.id);
    dialogRef.value?.close();
    emit('deleted');
  } catch (error) {
    useAlert(t('KANBAN.SETTINGS.DELETE_PIPELINE_ERROR'));
  }
};

const memberUserIds = computed(() => members.value.map(member => member.user_id));

const assignableAgents = computed(() =>
  agents.value.filter(agent => !memberUserIds.value.includes(agent.id))
);

const onAddMember = event => {
  const userId = Number(event.target.value);
  event.target.value = '';
  if (userId) dispatch('addMember', { userId });
};

const onRemoveMember = userId => dispatch('removeMember', { userId });

const onChangeRole = (userId, role) =>
  dispatch('updateMemberRole', { userId, role });

const MEMBER_ROLES = ['member', 'viewer'];


const stagesExcept = stageId => stages.value.filter(s => s.id !== stageId);

// Members load on open rather than on mount: the settings dialog lives inside the
// board, and the board should not pay for a request nobody asked for.
const open = () => {
  dialogRef.value?.open();
  dispatch('fetchMembers');
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    overflow-y-auto
    :title="t('KANBAN.SETTINGS.TITLE', { name: pipeline.name })"
    :description="t('KANBAN.SETTINGS.DESCRIPTION')"
    :show-confirm-button="false"
    :cancel-button-label="t('KANBAN.SETTINGS.CLOSE')"
  >
    <div class="flex flex-col gap-6">
      <section class="flex flex-col gap-2">
        <div class="flex items-center justify-between">
          <h4 class="m-0 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.SETTINGS.STAGES_TITLE') }}
          </h4>
          <span v-if="isSaving" class="text-xs text-n-slate-10">
            {{ t('KANBAN.SETTINGS.SAVING') }}
          </span>
        </div>

        <Draggable
          v-model="draggableStages"
          item-key="id"
          handle=".drag-handle"
          animation="180"
          ghost-class="opacity-40"
          class="flex flex-col gap-1.5"
        >
          <template #item="{ element }">
            <StageRow
              :stage="element"
              :task-count="taskCountByStage[element.id] || 0"
              :disabled="isSaving"
              @update="dispatch('updateStage', { id: element.id, ...$event })"
              @delete="onRequestDelete(element)"
            />
          </template>
        </Draggable>

        <div
          v-if="stagePendingDeletion"
          class="flex flex-wrap items-center gap-2 p-2 border rounded-lg border-n-ruby-6 bg-n-ruby-2"
        >
          <Icon icon="i-lucide-triangle-alert" class="size-4 text-n-ruby-9" />
          <p class="flex-1 min-w-0 m-0 text-xs text-n-slate-12">
            {{
              t('KANBAN.SETTINGS.DELETE_STAGE_CONFIRM', {
                name: stagePendingDeletion.name,
                count: taskCountByStage[stagePendingDeletion.id] || 0,
              })
            }}
          </p>
          <select
            v-if="taskCountByStage[stagePendingDeletion.id]"
            v-model="fallbackStageId"
            class="px-2 py-1 text-xs border rounded-md border-n-weak bg-n-solid-1 text-n-slate-12"
          >
            <option
              v-for="option in stagesExcept(stagePendingDeletion.id)"
              :key="option.id"
              :value="option.id"
            >
              {{ option.name }}
            </option>
          </select>
          <Button
            variant="solid"
            color="ruby"
            size="xs"
            :label="t('KANBAN.SETTINGS.CONFIRM_DELETE')"
            @click="onConfirmDelete"
          />
          <Button
            variant="ghost"
            color="slate"
            size="xs"
            :label="t('KANBAN.SETTINGS.CANCEL')"
            @click="stagePendingDeletion = null"
          />
        </div>

        <div class="flex items-center gap-2">
          <input
            v-model="newStageName"
            type="text"
            :placeholder="t('KANBAN.SETTINGS.NEW_STAGE_PLACEHOLDER')"
            class="flex-1 px-2.5 py-1.5 text-sm border rounded-lg border-n-weak bg-n-solid-1 text-n-slate-12 focus:border-n-brand focus:outline-none"
            @keyup.enter="onAddStage"
          />
          <Button
            variant="faded"
            color="slate"
            size="sm"
            icon="i-lucide-plus"
            :label="t('KANBAN.SETTINGS.ADD_STAGE')"
            :disabled="!newStageName.trim() || isSaving"
            @click="onAddStage"
          />
        </div>
      </section>

      <section class="flex flex-col gap-2">
        <h4 class="m-0 text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.SETTINGS.AUTOMATIONS_TITLE') }}
        </h4>
        <div
          v-for="flag in AUTOMATION_FLAGS"
          :key="flag.key"
          class="flex items-start justify-between gap-3 px-3 py-2 border rounded-lg border-n-weak bg-n-solid-1"
        >
          <div class="min-w-0">
            <p class="m-0 text-sm text-n-slate-12">
              {{ t(flag.labelKey) }}
            </p>
            <p class="m-0 text-xs text-n-slate-10">
              {{ t(flag.hintKey) }}
            </p>
          </div>
          <Switch
            :model-value="!!automation[flag.key]"
            :disabled="isSaving"
            @update:model-value="onToggleAutomation(flag.key, $event)"
          />
        </div>
      </section>

      <section class="flex flex-col gap-2">
        <div>
          <h4 class="m-0 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.SETTINGS.INBOXES_TITLE') }}
          </h4>
          <p class="m-0 text-xs text-n-slate-10">
            {{ t('KANBAN.SETTINGS.INBOXES_HINT') }}
          </p>
        </div>
        <div
          class="flex flex-col gap-1 p-1 overflow-y-auto border rounded-lg max-h-48 border-n-weak bg-n-solid-1"
        >
          <label
            v-for="inbox in inboxes"
            :key="inbox.id"
            class="flex items-center gap-2 px-2 py-1.5 rounded-md cursor-pointer hover:bg-n-solid-2"
          >
            <input
              type="checkbox"
              :checked="targetInboxIds.includes(inbox.id)"
              :disabled="isSaving"
              class="accent-n-brand"
              @change="onToggleInbox(inbox.id)"
            />
            <span class="text-sm truncate text-n-slate-12">
              {{ inbox.name }}
            </span>
          </label>
        </div>
      </section>

      <section class="flex flex-col gap-2">
        <div>
          <h4 class="m-0 text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.SETTINGS.MEMBERS_TITLE') }}
          </h4>
          <p class="m-0 text-xs text-n-slate-10">
            {{
              members.length
                ? t('KANBAN.SETTINGS.MEMBERS_HINT_RESTRICTED')
                : t('KANBAN.SETTINGS.MEMBERS_HINT_OPEN')
            }}
          </p>
        </div>

        <div
          v-for="member in members"
          :key="member.id"
          class="flex items-center gap-2 px-2 py-1.5 border rounded-lg border-n-weak bg-n-solid-1"
        >
          <Avatar
            :name="member.user.name"
            :src="member.user.thumbnail"
            :size="20"
            rounded-full
          />
          <span class="flex-1 min-w-0 text-sm truncate text-n-slate-12">
            {{ member.user.name }}
          </span>
          <select
            :value="member.role"
            :disabled="isSaving"
            class="px-2 py-1 text-xs border rounded-md border-n-weak bg-n-solid-1 text-n-slate-12"
            @change="onChangeRole(member.user_id, $event.target.value)"
          >
            <option v-for="role in MEMBER_ROLES" :key="role" :value="role">
              {{ t(`KANBAN.SETTINGS.ROLE.${role.toUpperCase()}`) }}
            </option>
          </select>
          <Button
            variant="faded"
            color="ruby"
            size="xs"
            icon="i-lucide-user-minus"
            :disabled="isSaving"
            :aria-label="t('KANBAN.SETTINGS.REMOVE_MEMBER')"
            @click="onRemoveMember(member.user_id)"
          />
        </div>

        <select
          :disabled="isSaving || !assignableAgents.length"
          class="px-2.5 py-1.5 text-sm border rounded-lg border-n-weak bg-n-solid-1 text-n-slate-12"
          @change="onAddMember"
        >
          <option value="">
            {{
              assignableAgents.length
                ? t('KANBAN.SETTINGS.ADD_MEMBER')
                : t('KANBAN.SETTINGS.NO_AGENTS_LEFT')
            }}
          </option>
          <option v-for="agent in assignableAgents" :key="agent.id" :value="agent.id">
            {{ agent.name }}
          </option>
        </select>
      </section>

      <section
        class="flex items-center justify-between gap-3 px-3 py-2 border rounded-lg border-n-ruby-6"
      >
        <div class="min-w-0">
          <p class="m-0 text-sm text-n-slate-12">
            {{ t('KANBAN.SETTINGS.DELETE_PIPELINE') }}
          </p>
          <p class="m-0 text-xs text-n-slate-10">
            {{ t('KANBAN.SETTINGS.DELETE_PIPELINE_HINT') }}
          </p>
        </div>
        <Button
          variant="faded"
          color="ruby"
          size="sm"
          :label="t('KANBAN.SETTINGS.DELETE_PIPELINE_ACTION')"
          @click="onDeletePipeline"
        />
      </section>
    </div>
  </Dialog>
</template>
