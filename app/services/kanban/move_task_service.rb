class Kanban::MoveTaskService
  pattr_initialize [:task!, :target_stage!, :target_position]

  # Single writer for stage_id/position: later slices hang real-time broadcasts and
  # webhooks off this one place rather than off every controller that touches a card.
  def perform
    ActiveRecord::Base.transaction do
      source_stage = task.stage
      insert_at = clamped_position(target_stage, task)

      shift_siblings_down(target_stage, insert_at, task)
      task.update!(kanban_stage_id: target_stage.id, position: insert_at)
      compact_positions(source_stage) if source_stage.id != target_stage.id
    end

    task.reload
  end

  private

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
