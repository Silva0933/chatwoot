// Pipeline stages are modeled as Chatwoot conversation labels (one label = one column).
// A conversation's "stage" is whichever of these labels it carries; moving a card
// between columns swaps that label, leaving every other label on the conversation intact.
export const PIPELINE_STAGES = [
  {
    labelTitle: 'novo-contato',
    name: 'Novo contato',
    color: '#7C6FE0',
    icon: 'i-lucide-circle-dot',
  },
  {
    labelTitle: 'em-atendimento',
    name: 'Em atendimento',
    color: '#1F93FF',
    icon: 'i-lucide-message-circle',
  },
  {
    labelTitle: 'aguardando-confirmacao',
    name: 'Aguardando confirmação',
    color: '#F5A623',
    icon: 'i-lucide-clock',
  },
  {
    labelTitle: 'agendado',
    name: 'Agendado',
    color: '#1CA7A0',
    icon: 'i-lucide-calendar-check',
  },
  {
    labelTitle: 'atendido',
    name: 'Atendido',
    color: '#2E9E5B',
    icon: 'i-lucide-check-circle-2',
  },
  {
    labelTitle: 'cancelado-faltou',
    name: 'Cancelado / faltou',
    color: '#E5484D',
    icon: 'i-lucide-x-circle',
  },
];

export const PIPELINE_LABEL_TITLES = PIPELINE_STAGES.map(s => s.labelTitle);
