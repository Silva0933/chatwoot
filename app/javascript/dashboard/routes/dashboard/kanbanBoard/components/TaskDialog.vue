<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import ContactAPI from 'dashboard/api/contacts';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import { PRIORITY_STYLES } from '../constants';

const props = defineProps({
  pipeline: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const task = ref(null);
const isSubmitting = ref(false);

const title = ref('');
const stageId = ref(null);
const priority = ref('medium');
const dueDate = ref('');
const assignedAgentId = ref(null);
const contactId = ref(null);
const contactOptions = ref([]);
const dealValue = ref('');
const lossReason = ref('');

const agents = useMapGetter('agents/getVerifiedAgents');

const isEditing = computed(() => !!task.value);
const stages = computed(() => props.pipeline.stages || []);

const stageOptions = computed(() =>
  stages.value.map(stage => ({ value: stage.id, label: stage.name }))
);

const priorityOptions = computed(() =>
  Object.entries(PRIORITY_STYLES).map(([value, style]) => ({
    value,
    label: t(style.label),
  }))
);

const agentOptions = computed(() => [
  { value: '', label: t('KANBAN.TASK.UNASSIGNED') },
  ...agents.value.map(agent => ({ value: agent.id, label: agent.name })),
]);

const isLostStage = computed(
  () => stages.value.find(s => s.id === stageId.value)?.is_lost_stage || false
);

const canSubmit = computed(
  () => title.value.trim() && stageId.value && (isEditing.value || contactId.value)
);

// The date input speaks YYYY-MM-DD; the API speaks ISO 8601.
const toDateInput = value => (value ? value.slice(0, 10) : '');

const open = (record = null, defaultStageId = null) => {
  task.value = record;
  title.value = record?.title || '';
  stageId.value = record?.stage_id || defaultStageId || stages.value[0]?.id || null;
  priority.value = record?.priority || 'medium';
  dueDate.value = toDateInput(record?.due_date);
  assignedAgentId.value = record?.assigned_agent?.id || '';
  contactId.value = record?.contact_id || null;
  dealValue.value = record?.value_cents ? String(record.value_cents / 100) : '';
  lossReason.value = record?.loss_reason || '';
  contactOptions.value = record?.contact
    ? [{ value: record.contact.id, label: record.contact.name }]
    : [];
  dialogRef.value?.open();
};

const onSearchContacts = async query => {
  if (!query) return;

  const { data } = await ContactAPI.search(query);
  contactOptions.value = data.payload.map(contact => ({
    value: contact.id,
    label: contact.name || contact.email || contact.phone_number,
  }));
};

const payload = () => ({
  title: title.value.trim(),
  priority: priority.value,
  due_date: dueDate.value || null,
  assigned_agent_id: assignedAgentId.value || null,
  // Cents on the wire: a BRL amount in a float loses money once the reports
  // start summing it.
  value_cents: Math.round(Number(dealValue.value.replace(',', '.') || 0) * 100),
  loss_reason: isLostStage.value ? lossReason.value.trim() || null : null,
});

const onConfirm = async () => {
  if (!canSubmit.value) return;

  isSubmitting.value = true;
  try {
    if (isEditing.value) {
      await store.dispatch('kanban/updateTask', { id: task.value.id, ...payload() });
      // Stage changes go through the move endpoint, which is the only writer of
      // stage_id and position, so the card lands at the bottom of its new column.
      if (stageId.value !== task.value.stage_id) {
        await store.dispatch('kanban/moveTask', {
          taskId: task.value.id,
          stageId: stageId.value,
        });
      }
    } else {
      await store.dispatch('kanban/createTask', {
        kanban_pipeline_id: props.pipeline.id,
        kanban_stage_id: stageId.value,
        contact_id: contactId.value,
        ...payload(),
      });
    }
    dialogRef.value?.close();
  } catch (error) {
    useAlert(error?.response?.data?.message || t('KANBAN.TASK.SAVE_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const onDelete = async () => {
  try {
    await store.dispatch('kanban/deleteTask', task.value.id);
    dialogRef.value?.close();
  } catch (error) {
    useAlert(t('KANBAN.TASK.DELETE_ERROR'));
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="md"
    overflow-y-auto
    :title="isEditing ? t('KANBAN.TASK.EDIT_TITLE') : t('KANBAN.TASK.NEW_TITLE')"
    :confirm-button-label="t('KANBAN.TASK.SAVE')"
    :disable-confirm-button="!canSubmit"
    :is-loading="isSubmitting"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-3">
      <label v-if="!isEditing" class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.TASK.CONTACT') }}
        </span>
        <ComboBox
          v-model="contactId"
          :options="contactOptions"
          use-api-results
          :placeholder="t('KANBAN.TASK.CONTACT_PLACEHOLDER')"
          :search-placeholder="t('KANBAN.TASK.CONTACT_SEARCH')"
          :empty-state="t('KANBAN.TASK.CONTACT_EMPTY')"
          @search="onSearchContacts"
        />
      </label>

      <label class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.TASK.TITLE_LABEL') }}
        </span>
        <input
          v-model="title"
          type="text"
          class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
        />
      </label>

      <div class="grid grid-cols-2 gap-3">
        <label class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.TASK.STAGE') }}
          </span>
          <select
            v-model="stageId"
            class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
          >
            <option v-for="o in stageOptions" :key="o.value" :value="o.value">
              {{ o.label }}
            </option>
          </select>
        </label>

        <label class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.TASK.PRIORITY') }}
          </span>
          <select
            v-model="priority"
            class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
          >
            <option v-for="o in priorityOptions" :key="o.value" :value="o.value">
              {{ o.label }}
            </option>
          </select>
        </label>

        <label class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.TASK.DUE_DATE') }}
          </span>
          <input
            v-model="dueDate"
            type="date"
            class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
          />
        </label>

        <label class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.TASK.VALUE') }}
          </span>
          <input
            v-model="dealValue"
            type="text"
            inputmode="decimal"
            :placeholder="t('KANBAN.TASK.VALUE_PLACEHOLDER')"
            class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
          />
        </label>

        <label class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('KANBAN.TASK.ASSIGNEE') }}
          </span>
          <select
            v-model="assignedAgentId"
            class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
          >
            <option v-for="o in agentOptions" :key="o.value" :value="o.value">
              {{ o.label }}
            </option>
          </select>
        </label>
      </div>

      <label v-if="isLostStage" class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.TASK.LOSS_REASON') }}
        </span>
        <input
          v-model="lossReason"
          type="text"
          :placeholder="t('KANBAN.TASK.LOSS_REASON_PLACEHOLDER')"
          class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
        />
        <span class="text-xs text-n-slate-10">
          {{ t('KANBAN.TASK.LOSS_REASON_HINT') }}
        </span>
      </label>

      <button
        v-if="isEditing"
        type="button"
        class="self-start text-xs text-n-ruby-11 hover:underline"
        @click="onDelete"
      >
        {{ t('KANBAN.TASK.DELETE') }}
      </button>
    </div>
  </Dialog>
</template>
