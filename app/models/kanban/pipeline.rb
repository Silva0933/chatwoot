class Kanban::Pipeline < ApplicationRecord
  include AccountCacheRevalidator

  self.table_name = 'kanban_pipelines'

  belongs_to :account

  has_many :stages,
           class_name: 'Kanban::Stage',
           foreign_key: :kanban_pipeline_id,
           dependent: :destroy,
           inverse_of: :pipeline
  has_many :tasks,
           class_name: 'Kanban::Task',
           foreign_key: :kanban_pipeline_id,
           dependent: :destroy,
           inverse_of: :pipeline
  has_many :pipeline_members,
           class_name: 'Kanban::PipelineMember',
           foreign_key: :kanban_pipeline_id,
           dependent: :destroy,
           inverse_of: :pipeline
  has_many :members, through: :pipeline_members, source: :user
  has_one :automation,
          class_name: 'Kanban::Automation',
          foreign_key: :kanban_pipeline_id,
          dependent: :destroy,
          inverse_of: :pipeline

  validates :name, presence: true, uniqueness: { scope: :account_id }

  scope :active, -> { where(is_active: true) }

  default_scope { order(:position, :id) }

  def won_stage
    stages.find_by(is_won_stage: true)
  end

  def lost_stage
    stages.find_by(is_lost_stage: true)
  end

  def first_stage
    stages.first
  end

  def push_event_data
    {
      id: id,
      name: name,
      description: description,
      is_active: is_active,
      position: position
    }
  end
end
