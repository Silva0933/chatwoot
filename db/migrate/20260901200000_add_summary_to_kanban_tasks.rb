class AddSummaryToKanbanTasks < ActiveRecord::Migration[7.1]
  # A card auto-created from a conversation is titled after the contact, so the
  # board showed a column of names and nothing about what any of them wanted.
  # The card falls back to the conversation's last message, which is free and
  # always current; this column is for the cases where someone wants to say it
  # in their own words instead ("retorno cardiologia, confirmar convênio").
  def change
    add_column :kanban_tasks, :summary, :string
  end
end
