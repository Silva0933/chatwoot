class CreateKanbanAutomations < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_automations do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanban_pipeline, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :auto_create_on_conversation, null: false, default: true
      t.boolean :auto_assign_task_to_agent, null: false, default: true
      t.boolean :auto_assign_conversation_to_agent, null: false, default: true
      t.boolean :auto_resolve_conversation_on_finish, null: false, default: true
      t.boolean :auto_win_task_on_resolve, null: false, default: true
      t.boolean :round_robin_assignment, null: false, default: false
      t.bigint :target_inbox_ids, null: false, default: [], array: true

      t.timestamps
    end

    add_index :kanban_automations, :kanban_pipeline_id, unique: true, name: 'index_kanban_automations_one_per_pipeline'
  end
end
