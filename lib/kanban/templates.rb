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
    },
    'legal' => {
      name: 'Escritório de Advocacia',
      description: 'Da consulta inicial ao contrato assinado, com triagem de viabilidade.',
      stages: [
        { name: 'Consulta inicial', color_hex: '#7C6FE0' },
        { name: 'Análise de viabilidade', color_hex: '#1F93FF' },
        { name: 'Proposta de honorários', color_hex: '#F5A623' },
        { name: 'Negociação', color_hex: '#E8863C' },
        { name: 'Contrato assinado', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Não prosseguiu', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'real_estate' => {
      name: 'Imobiliária',
      description: 'Do interesse no imóvel à assinatura, passando por visita e proposta.',
      stages: [
        { name: 'Interesse', color_hex: '#7C6FE0' },
        { name: 'Qualificação', color_hex: '#1F93FF' },
        { name: 'Visita agendada', color_hex: '#F5A623' },
        { name: 'Proposta enviada', color_hex: '#E8863C' },
        { name: 'Documentação', color_hex: '#1CA7A0' },
        { name: 'Fechado', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Perdido', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'aesthetics' => {
      name: 'Estética e Bem-estar',
      description: 'Da avaliação ao pacote fechado, com retorno e recorrência.',
      stages: [
        { name: 'Interesse', color_hex: '#7C6FE0' },
        { name: 'Avaliação agendada', color_hex: '#1F93FF' },
        { name: 'Orçamento enviado', color_hex: '#F5A623' },
        { name: 'Pacote fechado', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Desistiu', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'accounting' => {
      name: 'Contabilidade',
      description: 'Abertura e migração de empresas, do diagnóstico ao cliente ativo.',
      stages: [
        { name: 'Contato inicial', color_hex: '#7C6FE0' },
        { name: 'Diagnóstico', color_hex: '#1F93FF' },
        { name: 'Proposta enviada', color_hex: '#F5A623' },
        { name: 'Documentação pendente', color_hex: '#E8863C' },
        { name: 'Cliente ativo', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Não fechou', color_hex: '#E5484D', is_lost_stage: true }
      ]
    },
    'generic' => {
      name: 'Funil em branco',
      description: 'Quatro etapas neutras para adaptar a qualquer processo.',
      stages: [
        { name: 'Entrada', color_hex: '#7C6FE0' },
        { name: 'Em andamento', color_hex: '#1F93FF' },
        { name: 'Concluído', color_hex: '#2E9E5B', is_won_stage: true },
        { name: 'Descartado', color_hex: '#E5484D', is_lost_stage: true }
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
