class Kanban::BuildPipelineService
  pattr_initialize [:account!, :params!]

  def perform
    ActiveRecord::Base.transaction do
      pipeline = account.kanban_pipelines.create!(
        name: params[:name].presence || template&.fetch(:name),
        description: params[:description].presence || template&.dig(:description),
        position: account.kanban_pipelines.count
      )
      build_stages(pipeline)
      build_automation(pipeline)
      pipeline
    end
  end

  private

  def template
    @template ||= Kanban::Templates.find(params[:template_key]) if params[:template_key].present?
  end

  def stage_attributes
    return params[:stages] if params[:stages].present?
    return template[:stages] if template.present?

    Kanban::Templates.find(Kanban::Templates::DEFAULT_TEMPLATE_KEY)[:stages]
  end

  # Only the account's first pipeline auto-creates cards. Without this guard every
  # later pipeline would also claim each new conversation, so one conversation would
  # fan out into a card on every board.
  def build_automation(pipeline)
    pipeline.create_automation!(
      account_id: pipeline.account_id,
      auto_create_on_conversation: account.kanban_pipelines.count == 1
    )
  end

  def build_stages(pipeline)
    stage_attributes.each_with_index do |attrs, index|
      attrs = attrs.symbolize_keys
      pipeline.stages.create!(
        account_id: pipeline.account_id,
        name: attrs[:name],
        color_hex: attrs[:color_hex].presence || '#4A86E8',
        is_won_stage: ActiveModel::Type::Boolean.new.cast(attrs[:is_won_stage]) || false,
        is_lost_stage: ActiveModel::Type::Boolean.new.cast(attrs[:is_lost_stage]) || false,
        position: index
      )
    end
  end
end
