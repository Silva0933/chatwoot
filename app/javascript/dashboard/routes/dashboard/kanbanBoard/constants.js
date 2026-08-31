export const PRIORITY_STYLES = {
  urgent: { label: 'KANBAN.PRIORITY.URGENT', class: 'bg-n-ruby-3 text-n-ruby-11' },
  high: { label: 'KANBAN.PRIORITY.HIGH', class: 'bg-n-amber-3 text-n-amber-11' },
  medium: { label: 'KANBAN.PRIORITY.MEDIUM', class: 'bg-n-blue-3 text-n-blue-11' },
  low: { label: 'KANBAN.PRIORITY.LOW', class: 'bg-n-slate-3 text-n-slate-11' },
};

export const CHANNEL_ICONS = {
  'Channel::WebWidget': 'i-lucide-globe',
  'Channel::Whatsapp': 'i-ri-whatsapp-fill',
  'Channel::Email': 'i-lucide-mail',
  'Channel::FacebookPage': 'i-ri-messenger-fill',
  'Channel::Instagram': 'i-ri-instagram-fill',
  'Channel::Telegram': 'i-ri-telegram-fill',
  'Channel::Sms': 'i-lucide-message-square',
  'Channel::Api': 'i-lucide-webhook',
};

export const DEFAULT_CHANNEL_ICON = 'i-lucide-inbox';

// SLA colour bands from the PRD: green while there is room, amber on the due day,
// red once the due date has passed.
export const SLA_STATE = {
  ON_TRACK: 'on_track',
  DUE_TODAY: 'due_today',
  OVERDUE: 'overdue',
};

export const SLA_STYLES = {
  [SLA_STATE.ON_TRACK]: 'text-n-teal-11',
  [SLA_STATE.DUE_TODAY]: 'text-n-amber-11',
  [SLA_STATE.OVERDUE]: 'text-n-ruby-11',
};

export const slaStateFor = dueDate => {
  if (!dueDate) return null;
  const due = new Date(dueDate);
  const now = new Date();
  if (due < now) return SLA_STATE.OVERDUE;
  if (due.toDateString() === now.toDateString()) return SLA_STATE.DUE_TODAY;
  return SLA_STATE.ON_TRACK;
};

// Only the flags KanbanListener actually honours are exposed. The remaining three
// columns exist in the table but nothing reads them yet, and a toggle that changes
// nothing is worse than a missing one.
export const AUTOMATION_FLAGS = [
  {
    key: 'auto_create_on_conversation',
    labelKey: 'KANBAN.SETTINGS.AUTOMATION.CREATE.LABEL',
    hintKey: 'KANBAN.SETTINGS.AUTOMATION.CREATE.HINT',
  },
  {
    key: 'auto_assign_task_to_agent',
    labelKey: 'KANBAN.SETTINGS.AUTOMATION.ASSIGN_TASK.LABEL',
    hintKey: 'KANBAN.SETTINGS.AUTOMATION.ASSIGN_TASK.HINT',
  },
  {
    key: 'auto_win_task_on_resolve',
    labelKey: 'KANBAN.SETTINGS.AUTOMATION.WIN_ON_RESOLVE.LABEL',
    hintKey: 'KANBAN.SETTINGS.AUTOMATION.WIN_ON_RESOLVE.HINT',
  },
];

// Averages come back in seconds; a column header has room for "3d", not "268412s".
export const formatDuration = (seconds, t) => {
  if (seconds === null || seconds === undefined) return '—';

  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return t('KANBAN.CARD.TIME_MINUTES', { count: minutes });

  const hours = Math.round(minutes / 60);
  if (hours < 24) return t('KANBAN.CARD.TIME_HOURS', { count: hours });

  return t('KANBAN.CARD.TIME_DAYS', { count: Math.round(hours / 24) });
};

// Channel identity for the card chip: a dot in the channel's own colour plus its
// short name, which reads faster in a dense column than an icon alone.
export const CHANNEL_META = {
  'Channel::Whatsapp': { label: 'whatsapp', dot: '#25D366' },
  'Channel::Email': { label: 'email', dot: '#8B7BE8' },
  'Channel::Instagram': { label: 'instagram', dot: '#E1306C' },
  'Channel::FacebookPage': { label: 'messenger', dot: '#0084FF' },
  'Channel::Telegram': { label: 'telegram', dot: '#2AABEE' },
  'Channel::Sms': { label: 'sms', dot: '#F5A623' },
  'Channel::WebWidget': { label: 'webchat', dot: '#1F93FF' },
  'Channel::Api': { label: 'api', dot: '#8E8E93' },
};

export const DEFAULT_CHANNEL_META = { label: 'inbox', dot: '#8E8E93' };

// Priority as a glyph rather than a word: the column is narrow, and direction
// reads at a glance where a coloured label competes with the contact's name.
export const PRIORITY_GLYPHS = {
  urgent: { icon: 'i-lucide-chevrons-up', class: 'text-n-ruby-10' },
  high: { icon: 'i-lucide-chevron-up', class: 'text-n-amber-10' },
  medium: { icon: 'i-lucide-equal', class: 'text-n-blue-10' },
  low: { icon: 'i-lucide-chevron-down', class: 'text-n-slate-10' },
};

// A stage colour is picked by the admin, so the header text has to adapt to it
// instead of assuming a dark background. Rec. 601 luma, the usual threshold.
export const readableTextOn = hex => {
  const value = String(hex || '').replace('#', '');
  const full =
    value.length === 3
      ? value
          .split('')
          .map(c => c + c)
          .join('')
      : value;
  if (full.length !== 6) return '#FFFFFF';

  const [r, g, b] = [0, 2, 4].map(i => parseInt(full.slice(i, i + 2), 16));
  return (r * 299 + g * 587 + b * 114) / 1000 > 150 ? '#111111' : '#FFFFFF';
};

// Near dates read better as words: "Hoje" tells an agent to act, "31 de out."
// makes them do the arithmetic themselves.
export const formatDueDate = (dueDate, t, locale) => {
  if (!dueDate) return null;

  const due = new Date(dueDate);
  const startOfDay = date =>
    new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  const days = Math.round(
    (startOfDay(due) - startOfDay(new Date())) / 86400000
  );

  if (days === 0) return t('KANBAN.CARD.DUE_TODAY');
  if (days === 1) return t('KANBAN.CARD.DUE_TOMORROW');
  if (days === -1) return t('KANBAN.CARD.DUE_YESTERDAY');

  return due.toLocaleDateString(locale, { day: 'numeric', month: 'short' });
};

export const SORT_OPTIONS = [
  { value: 'position', labelKey: 'KANBAN.FILTERS.SORT_MANUAL' },
  { value: 'due_date', labelKey: 'KANBAN.FILTERS.SORT_DUE' },
  { value: 'priority', labelKey: 'KANBAN.FILTERS.SORT_PRIORITY' },
  { value: 'stage_entered_at', labelKey: 'KANBAN.FILTERS.SORT_OLDEST' },
];

const PRIORITY_WEIGHT = { urgent: 0, high: 1, medium: 2, low: 3 };

// Sorting never mutates: the array comes from a Vuex getter, and reordering it in
// place would fight the drag-and-drop that owns the real order.
export const sortTasks = (tasks, sortBy) => {
  const sorted = [...tasks];

  if (sortBy === 'due_date') {
    // Cards with no due date sink; among the rest the nearest deadline leads.
    return sorted.sort((a, b) => {
      if (!a.due_date) return b.due_date ? 1 : 0;
      if (!b.due_date) return -1;
      return new Date(a.due_date) - new Date(b.due_date);
    });
  }

  if (sortBy === 'priority') {
    return sorted.sort(
      (a, b) => PRIORITY_WEIGHT[a.priority] - PRIORITY_WEIGHT[b.priority]
    );
  }

  if (sortBy === 'stage_entered_at') {
    return sorted.sort(
      (a, b) => new Date(a.stage_entered_at) - new Date(b.stage_entered_at)
    );
  }

  return sorted.sort((a, b) => a.position - b.position);
};

// Values travel as cents so the API never rounds money; the board is the only
// place that turns them back into currency.
export const formatMoney = (cents, locale) => {
  if (!cents) return null;
  return (cents / 100).toLocaleString(locale || 'pt-BR', {
    style: 'currency',
    currency: 'BRL',
    maximumFractionDigits: 0,
  });
};
