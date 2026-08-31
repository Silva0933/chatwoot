class CreateKanbanStages < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_stages do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanban_pipeline, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :is_won_stage, null: false, default: false
      t.boolean :is_lost_stage, null: false, default: false
      t.string :color_hex, null: false, default: '#4A86E8'

      t.timestamps
    end

    add_index :kanban_stages, [:kanban_pipeline_id, :position]
    # A pipeline has at most one terminal stage of each kind, so moving a card to
    # "won"/"lost" resolves to a single unambiguous column.
    add_index :kanban_stages, :kanban_pipeline_id, unique: true, where: 'is_won_stage', name: 'index_kanban_stages_one_won_per_pipeline'
    add_index :kanban_stages, :kanban_pipeline_id, unique: true, where: 'is_lost_stage', name: 'index_kanban_stages_one_lost_per_pipeline'
  end
end
