class Kanban::MoveTaskService
  include Events::Types

  pattr_initialize [:task!, :target_stage!, :target_position]

  # Single writer for stage_id/position, which is why the real-time broadcast and
  # the webhooks hang off here instead of off every caller that moves a card.
  def perform
    source_stage = task.stage
    seconds_in_stage = task.seconds_in_stage

    ActiveRecord::Base.transaction do
      insert_at = clamped_position(target_stage, task)

      shift_siblings_down(target_stage, insert_at, task)
      task.update!(kanban_stage_id: target_stage.id, position: insert_at)

      if source_stage.id != target_stage.id
        compact_positions(source_stage)
        record_transition(source_stage, seconds_in_stage)
      end
    end

    task.reload
    dispatch_events(source_stage)
    task
  end

  private

  # Written inside the move transaction so the log can never claim a transition the
  # card did not actually make.
  def record_transition(source_stage, seconds_in_stage)
    Kanban::TaskTransition.create!(
      account_id: task.account_id,
      kanban_pipeline_id: task.kanban_pipeline_id,
      kanban_task_id: task.id,
      from_stage_id: source_stage.id,
      to_stage_id: target_stage.id,
      seconds_in_previous_stage: seconds_in_stage.to_i
    )
  end

  # Reordering inside a column is not a funnel event: only a real stage change is
  # worth waking automations and other agents' boards.
  def dispatch_events(source_stage)
    return if source_stage.id == target_stage.id

    dispatch(KANBAN_TASK_MOVED, from_stage_id: source_stage.id)
    dispatch(KANBAN_TASK_WON) if target_stage.is_won_stage?
    dispatch(KANBAN_TASK_LOST) if target_stage.is_lost_stage?
  end

  def dispatch(event_name, extra = {})
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, { task: task }.merge(extra))
  end

  def clamped_position(stage, moving_task)
    siblings = sibling_ids(stage, moving_task)
    return siblings.length if target_position.blank?

    target_position.to_i.clamp(0, siblings.length)
  end

  def sibling_ids(stage, moving_task)
    stage.tasks.where.not(id: moving_task.id).pluck(:id)
  end

  def shift_siblings_down(stage, insert_at, moving_task)
    stage.tasks
         .where.not(id: moving_task.id)
         .where(position: insert_at..)
         .update_all('position = position + 1')
  end

  # Closes the gap the card left behind so positions stay contiguous and a later
  # insert index means the same thing on both sides of the board.
  def compact_positions(stage)
    stage.tasks.reload.each_with_index do |sibling, index|
      sibling.update_columns(position: index) if sibling.position != index
    end
  end
end
