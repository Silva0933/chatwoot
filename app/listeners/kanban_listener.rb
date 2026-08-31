class KanbanListener < BaseListener
  def conversation_created(event)
    conversation, account = extract_conversation_and_account(event)

    automations_for(account, conversation).each do |automation|
      next unless automation.auto_create_on_conversation?

      create_task(automation.pipeline, conversation)
    end
  end

  def conversation_resolved(event)
    conversation, account = extract_conversation_and_account(event)

    tasks_for(account, conversation).each do |task|
      automation = task.pipeline.automation
      next unless automation&.auto_win_task_on_resolve?

      won_stage = task.pipeline.won_stage
      next if won_stage.blank? || task.kanban_stage_id == won_stage.id

      Kanban::MoveTaskService.new(task: task, target_stage: won_stage).perform
    end
  end

  # Mirrors the Chatwoot assignee onto the card so the board shows who owns the
  # conversation without the agent having to set it twice.
  #
  # The assignee change has to come from the event payload, not from the record:
  # this listener runs through EventDispatcherJob, so the conversation arrives
  # re-loaded from the database and its dirty-tracking is already gone.
  def conversation_updated(event)
    conversation, account = extract_conversation_and_account(event)
    return unless assignee_changed?(event)

    tasks_for(account, conversation).each do |task|
      next unless task.pipeline.automation&.auto_assign_task_to_agent?

      task.update(assigned_agent_id: conversation.assignee_id)
    end
  end

  private

  def assignee_changed?(event)
    changed_attributes = event.data[:changed_attributes]
    return false if changed_attributes.blank?

    changed_attributes.key?('assignee_id') || changed_attributes.key?(:assignee_id)
  end

  def automations_for(account, conversation)
    Kanban::Automation
      .joins(:pipeline)
      .where(account_id: account.id, kanban_pipelines: { is_active: true })
      .select { |automation| automation.targets_inbox?(conversation.inbox_id) }
  end

  def tasks_for(account, conversation)
    account.kanban_tasks.where(conversation_id: conversation.id).includes(pipeline: :automation)
  end

  def create_task(pipeline, conversation)
    stage = pipeline.first_stage
    return if stage.blank?

    pipeline.tasks.create!(
      account_id: pipeline.account_id,
      kanban_stage_id: stage.id,
      conversation_id: conversation.id,
      contact_id: conversation.contact_id,
      inbox_id: conversation.inbox_id,
      assigned_agent_id: conversation.assignee_id,
      title: task_title(conversation),
      stage_entered_at: Time.zone.now,
      position: stage.tasks.count
    )
  rescue ActiveRecord::RecordNotUnique
    # The unique index on (pipeline, conversation) is the source of truth here: a
    # reopened conversation must not spawn a second card.
    nil
  end

  def task_title(conversation)
    conversation.contact&.name.presence || "Conversa ##{conversation.display_id}"
  end
end
