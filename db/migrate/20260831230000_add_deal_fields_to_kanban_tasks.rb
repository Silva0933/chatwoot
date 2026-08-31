class AddDealFieldsToKanbanTasks < ActiveRecord::Migration[7.1]
  # A funnel without a value is a task board. Money is what makes the same board
  # work for a law firm, an agency or a dealership, and what makes "how much is in
  # Negotiation" answerable at all.
  #
  # Stored in cents: BRL amounts in a float lose money at the third decimal, and
  # every report here sums them.
  def change
    add_column :kanban_tasks, :value_cents, :bigint, null: false, default: 0
    # Why a deal was lost is the one field a closed funnel is asked for later, and
    # it cannot be reconstructed from the stage alone.
    add_column :kanban_tasks, :loss_reason, :string

    add_index :kanban_tasks, [:kanban_pipeline_id, :value_cents]
  end
end
