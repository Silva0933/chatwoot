class Kanban::TaskTransition < ApplicationRecord
  self.table_name = 'kanban_task_transitions'

  belongs_to :account
  belongs_to :pipeline,
             class_name: 'Kanban::Pipeline',
             foreign_key: :kanban_pipeline_id,
             inverse_of: :task_transitions
  belongs_to :task,
             class_name: 'Kanban::Task',
             foreign_key: :kanban_task_id,
             inverse_of: :transitions
end
