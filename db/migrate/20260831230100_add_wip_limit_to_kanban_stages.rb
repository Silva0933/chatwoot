class AddWipLimitToKanbanStages < ActiveRecord::Migration[7.1]
  # The Kanban rule the method is named after: a column that holds more than it can
  # work is where the funnel actually breaks. Null means no limit, which is the
  # right default for a stage nobody has thought about yet.
  def change
    add_column :kanban_stages, :wip_limit, :integer
  end
end
