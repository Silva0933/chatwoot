class CreateKanbanTaskTransitions < ActiveRecord::Migration[7.1]
  # kanban_tasks only knows where a card is now, so no query over it can answer
  # "how many leads made it from Avaliação to Agendado". This is the log that makes
  # the passage rate and the bottleneck view possible.
  def change
    create_table :kanban_task_transitions do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanban_pipeline, null: false, foreign_key: { on_delete: :cascade }
      t.references :kanban_task, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :from_stage_id
      t.bigint :to_stage_id, null: false
      # Seconds the card spent in the stage it just left: computing it here keeps the
      # reports from re-deriving it by walking every row in order.
      t.integer :seconds_in_previous_stage

      t.timestamps
    end

    add_index :kanban_task_transitions, [:kanban_pipeline_id, :created_at]
    add_index :kanban_task_transitions, [:kanban_pipeline_id, :from_stage_id, :to_stage_id],
              name: 'index_kanban_transitions_on_pipeline_and_stages'
  end
end
