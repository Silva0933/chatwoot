class CreateKanbanTasks < ActiveRecord::Migration[7.1]
  def change
    create_kanban_tasks
    add_kanban_task_indexes
  end

  private

  def create_kanban_tasks
    create_table :kanban_tasks do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanban_pipeline, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanban_stage, null: false, foreign_key: { on_delete: :restrict }
      t.references :conversation, foreign_key: { on_delete: :nullify }
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.references :assigned_agent, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :inbox, foreign_key: { on_delete: :nullify }
      t.string :title, null: false
      t.integer :priority, null: false, default: 1
      t.datetime :due_date
      t.datetime :stage_entered_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end

  def add_kanban_task_indexes
    add_index :kanban_tasks, [:kanban_stage_id, :position]
    add_index :kanban_tasks, [:account_id, :kanban_pipeline_id]
    add_index :kanban_tasks, [:kanban_pipeline_id, :assigned_agent_id]
    # One card per conversation per pipeline, so the auto-create automation in a
    # later slice cannot duplicate a card when a conversation is reopened.
    add_index :kanban_tasks, [:kanban_pipeline_id, :conversation_id], unique: true, where: 'conversation_id IS NOT NULL',
                             name: 'index_kanban_tasks_one_card_per_conversation'
  end
end
