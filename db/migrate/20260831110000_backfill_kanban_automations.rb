class BackfillKanbanAutomations < ActiveRecord::Migration[7.1]
  # Pipelines created before the automation engine existed have no automation row,
  # so the listener would silently skip them. Give each one the defaults, enabling
  # auto-create only on the account's first pipeline.
  def up
    Kanban::Pipeline.reset_column_information

    Kanban::Pipeline.find_each do |pipeline|
      next if Kanban::Automation.exists?(kanban_pipeline_id: pipeline.id)

      is_first = Kanban::Pipeline.where(account_id: pipeline.account_id).order(:position, :id).first&.id == pipeline.id

      Kanban::Automation.create!(
        account_id: pipeline.account_id,
        kanban_pipeline_id: pipeline.id,
        auto_create_on_conversation: is_first
      )
    end
  end

  def down
    # Nothing to undo: dropping the rows would disable automations that may have
    # been reconfigured by hand since.
  end
end
