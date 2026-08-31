module Kanban::Templates
  TEMPLATES = {
    'patient_acquisition' => {
      name: 'Captação de Pacientes',
      description: 'Da primeira mensagem até o paciente comparecer na consulta.',
      stages: [
        { name: 'Novo contato', color_hex: '#7C6FE0' },
        { name: 'Avaliação', color_hex: '#1F93FF' },
        { name: 'Aguardando confirmação', color_hex: '#F5A623' },
        { name: 'Agendado', color_hex: '#1CA7A0' },
        { name: 'Compareceu', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Não compareceu', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'post_treatment' => {
      name: 'Pós-atendimento',
      description: 'Acompanhamento de retornos, exames e recorrência.',
      stages: [
        { name: 'Aguardando exames', color_hex: '#7C6FE0' },
        { name: 'Resultado entregue', color_hex: '#1F93FF' },
        { name: 'Retorno agendado', color_hex: '#1CA7A0' },
        { name: 'Tratamento concluído', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Abandonou tratamento', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'sales' => {
      name: 'Pipeline de Vendas',
      description: 'Funil comercial padrão, do lead à venda fechada.',
      stages: [
        { name: 'Novo lead', color_hex: '#7C6FE0' },
        { name: 'Qualificação', color_hex: '#1F93FF' },
        { name: 'Proposta enviada', color_hex: '#F5A623' },
        { name: 'Negociação', color_hex: '#1CA7A0' },
        { name: 'Ganho', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Perdido', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'support' => {
      name: 'Suporte Técnico',
      description: 'Triagem e resolução de chamados de suporte.',
      stages: [
        { name: 'Aberto', color_hex: '#7C6FE0' },
        { name: 'Em análise', color_hex: '#1F93FF' },
        { name: 'Aguardando cliente', color_hex: '#F5A623' },
        { name: 'Resolvido', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Cancelado', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'recruitment' => {
      name: 'Recrutamento e Seleção',
      description: 'Acompanhamento de candidatos, da inscrição à contratação.',
      stages: [
        { name: 'Inscrito', color_hex: '#7C6FE0' },
        { name: 'Triagem', color_hex: '#1F93FF' },
        { name: 'Entrevista', color_hex: '#F5A623' },
        { name: 'Proposta', color_hex: '#1CA7A0' },
        { name: 'Contratado', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Reprovado', color_hex: '#E5484D', is_lost_stage: true }
      ]
    }
  }.freeze

  DEFAULT_TEMPLATE_KEY = 'patient_acquisition'.freeze

  module_function

  def find(key)
    TEMPLATES[key.to_s]
  end

  def keys
    TEMPLATES.keys
  end
end
