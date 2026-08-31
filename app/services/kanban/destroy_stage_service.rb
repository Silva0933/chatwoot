class Kanban::DestroyStageService
  # Raised instead of letting the foreign key blow up, so the controller can turn
  # it into a message that tells the admin what to do about it.
  class StageNotEmptyError < StandardError; end

  # A funnel with no columns has nowhere to put a card, which would break every
  # write path downstream. Refuse here rather than guarding each of them.
  class LastStageError < StandardError; end

  pattr_initialize [:stage!, :fallback_stage]

  def perform
    raise LastStageError if stage.pipeline.stages.count == 1

    ActiveRecord::Base.transaction do
      relocate_tasks if stage.tasks.exists?
      stage.destroy!
    end
  end

  private

  # kanban_tasks.kanban_stage_id is ON DELETE RESTRICT: a card must always sit in a
  # real column. Deleting a populated stage therefore has to say where its cards go
  # rather than silently discarding them.
  def relocate_tasks
    raise StageNotEmptyError if fallback_stage.blank?
    raise StageNotEmptyError if fallback_stage.id == stage.id

    offset = fallback_stage.tasks.maximum(:position).to_i + 1

    stage.tasks.order(:position, :id).each_with_index do |task, index|
      task.update!(kanban_stage_id: fallback_stage.id, position: offset + index)
    end
  end
end
