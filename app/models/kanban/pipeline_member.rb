class Kanban::PipelineMember < ApplicationRecord
  self.table_name = 'kanban_pipeline_members'

  belongs_to :pipeline,
             class_name: 'Kanban::Pipeline',
             foreign_key: :kanban_pipeline_id,
             inverse_of: :pipeline_members
  belongs_to :user

  enum :role, { viewer: 0, member: 1, admin: 2 }, prefix: true

  validates :user_id, uniqueness: { scope: :kanban_pipeline_id }
end
