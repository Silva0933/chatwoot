class BackfillKanbanTasksForOpenConversations < ActiveRecord::Migration[7.1]
  # Without this the board only fills up as new conversations arrive, so an account
  # that already has history sees an empty Kanban. Only unresolved conversations are
  # imported: a resolved chat is not evidence the funnel actually completed, so
  # dropping those into the "won" stage would misreport the pipeline.
  def up
    Kanban::Pipeline.reset_column_information
    Kanban::Task.reset_column_information

    Kanban::Automation.where(auto_create_on_conversation: true).includes(:pipeline).find_each do |automation|
      backfill_pipeline(automation)
    end
  end

  def down
    # Cards may have been moved or edited by hand since; deleting them would discard
    # that work.
  end

  private

  def backfill_pipeline(automation)
    pipeline = automation.pipeline
    stage = pipeline.stages.order(:position, :id).first
    return if stage.blank?

    position = stage.tasks.count

    conversations(pipeline.account_id, automation).find_each do |conversation|
      next if Kanban::Task.exists?(kanban_pipeline_id: pipeline.id, conversation_id: conversation.id)

      create_task(pipeline, stage, conversation, position)
      position += 1
    end
  end

  def conversations(account_id, automation)
    scope = Conversation.where(account_id: account_id).where.not(status: Conversation.statuses[:resolved])
    scope = scope.where(inbox_id: automation.target_inbox_ids) if automation.target_inbox_ids.present?
    scope
  end

  def create_task(pipeline, stage, conversation, position)
    Kanban::Task.create!(
      account_id: pipeline.account_id,
      kanban_pipeline_id: pipeline.id,
      kanban_stage_id: stage.id,
      conversation_id: conversation.id,
      contact_id: conversation.contact_id,
      inbox_id: conversation.inbox_id,
      assigned_agent_id: conversation.assignee_id,
      title: conversation.contact&.name.presence || "Conversa ##{conversation.display_id}",
      stage_entered_at: conversation.created_at,
      position: position
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("[kanban backfill] skipped conversation #{conversation.id}: #{e.message}")
  end
end
