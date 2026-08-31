<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['created']);

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const name = ref('');
const selectedTemplateKey = ref(null);
const isSubmitting = ref(false);

const templates = useMapGetter('kanban/getTemplates');

const selectedTemplate = computed(() =>
  templates.value.find(template => template.key === selectedTemplateKey.value)
);

const open = async () => {
  name.value = '';
  selectedTemplateKey.value = null;
  dialogRef.value?.open();
  await store.dispatch('kanban/fetchTemplates');
};

const onSelectTemplate = template => {
  selectedTemplateKey.value = template.key;
  // The name field is a suggestion the admin can overwrite, so only prefill it
  // while it still holds another template's suggestion.
  if (!name.value.trim() || templates.value.some(t2 => t2.name === name.value)) {
    name.value = template.name;
  }
};

const onConfirm = async () => {
  if (!selectedTemplateKey.value || !name.value.trim()) return;

  isSubmitting.value = true;
  try {
    const pipeline = await store.dispatch('kanban/createPipeline', {
      name: name.value.trim(),
      description: selectedTemplate.value?.description,
      template_key: selectedTemplateKey.value,
    });
    dialogRef.value?.close();
    emit('created', pipeline);
  } catch (error) {
    useAlert(
      error?.response?.data?.message || t('KANBAN.NEW_PIPELINE.CREATE_ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="xl"
    overflow-y-auto
    :title="t('KANBAN.NEW_PIPELINE.TITLE')"
    :description="t('KANBAN.NEW_PIPELINE.DESCRIPTION')"
    :confirm-button-label="t('KANBAN.NEW_PIPELINE.CONFIRM')"
    :disable-confirm-button="!selectedTemplateKey || !name.trim()"
    :is-loading="isSubmitting"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <label class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.NEW_PIPELINE.NAME_LABEL') }}
        </span>
        <input
          v-model="name"
          type="text"
          :placeholder="t('KANBAN.NEW_PIPELINE.NAME_PLACEHOLDER')"
          class="w-full h-9 px-2.5 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors"
        />
      </label>

      <div class="flex flex-col gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.NEW_PIPELINE.TEMPLATE_LABEL') }}
        </span>
        <button
          v-for="template in templates"
          :key="template.key"
          type="button"
          class="flex flex-col gap-1.5 px-3 py-2 text-left border rounded-lg transition-colors"
          :class="
            template.key === selectedTemplateKey
              ? 'border-n-brand bg-n-solid-2'
              : 'border-n-weak bg-n-solid-1 hover:border-n-strong'
          "
          @click="onSelectTemplate(template)"
        >
          <span class="flex items-center gap-2">
            <Icon
              :icon="
                template.key === selectedTemplateKey
                  ? 'i-lucide-circle-check-big'
                  : 'i-lucide-circle'
              "
              class="size-3.5 text-n-slate-11"
            />
            <span class="text-sm font-medium text-n-slate-12">
              {{ template.name }}
            </span>
          </span>
          <span class="text-xs text-n-slate-10">{{ template.description }}</span>
          <!-- The chips carry each stage's own colour so the picker previews the
               board the template will actually build. -->
          <span class="flex flex-wrap gap-1">
            <span
              v-for="stage in template.stages"
              :key="stage.name"
              class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[11px] leading-none text-n-slate-11 bg-n-solid-3"
            >
              <span
                class="rounded-full size-1.5"
                :style="{ backgroundColor: stage.color_hex }"
              />
              {{ stage.name }}
            </span>
          </span>
        </button>
      </div>
    </div>
  </Dialog>
</template>
