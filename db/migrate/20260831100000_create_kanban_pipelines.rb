class CreateKanbanPipelines < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_pipelines do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :kanban_pipelines, [:account_id, :name], unique: true
    add_index :kanban_pipelines, [:account_id, :is_active]
  end
end
