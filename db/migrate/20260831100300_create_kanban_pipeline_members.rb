class CreateKanbanPipelineMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_pipeline_members do |t|
      t.references :kanban_pipeline, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :role, null: false, default: 1

      t.timestamps
    end

    add_index :kanban_pipeline_members, [:kanban_pipeline_id, :user_id], unique: true, name: 'index_kanban_pipeline_members_uniqueness'
  end
end
