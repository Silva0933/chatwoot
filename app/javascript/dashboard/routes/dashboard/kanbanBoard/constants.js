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
