class Kanban::Automation < ApplicationRecord
  self.table_name = 'kanban_automations'

  belongs_to :account
  belongs_to :pipeline,
             class_name: 'Kanban::Pipeline',
             foreign_key: :kanban_pipeline_id,
             inverse_of: :automation

  def targets_inbox?(inbox_id)
    target_inbox_ids.blank? || target_inbox_ids.include?(inbox_id)
  end
end
