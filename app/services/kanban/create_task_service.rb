class Kanban::CreateTaskService
  include Events::Types

  # Single entry point for card creation: the board, the API and the conversation
  # listener all come through here, so the created event fires exactly once per
  # card no matter who asked for it.
  pattr_initialize [:pipeline!, :params!]

  def perform
    task = pipeline.tasks.create!(attributes)
    Rails.configuration.dispatcher.dispatch(KANBAN_TASK_CREATED, Time.zone.now, task: task)
    task
  end

  private

  def attributes
    stage = target_stage

    params.to_h.symbolize_keys.merge(
      account_id: pipeline.account_id,
      kanban_stage_id: stage.id,
      stage_entered_at: Time.zone.now,
      position: stage.tasks.count
    )
  end

  # A card always belongs to a column. Callers that do not care which one land on
  # the first stage, which is what "a new lead enters the funnel" means.
  def target_stage
    stage_id = params[:kanban_stage_id]
    return pipeline.stages.find(stage_id) if stage_id.present?

    pipeline.first_stage
  end
end
