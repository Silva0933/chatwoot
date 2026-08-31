class Kanban::Stage < ApplicationRecord
  include AccountCacheRevalidator

  self.table_name = 'kanban_stages'

  belongs_to :account
  belongs_to :pipeline,
             class_name: 'Kanban::Pipeline',
             foreign_key: :kanban_pipeline_id,
             inverse_of: :stages

  has_many :tasks,
           class_name: 'Kanban::Task',
           foreign_key: :kanban_stage_id,
           dependent: :restrict_with_error,
           inverse_of: :stage

  validates :name, presence: true, uniqueness: { scope: :kanban_pipeline_id }
  validates :color_hex, format: { with: /\A#(?:\h{3}|\h{6})\z/ }
  validate :terminal_kinds_are_exclusive

  default_scope { order(:position, :id) }

  def terminal?
    is_won_stage? || is_lost_stage?
  end

  def push_event_data
    {
      id: id,
      pipeline_id: kanban_pipeline_id,
      name: name,
      position: position,
      is_won_stage: is_won_stage,
      is_lost_stage: is_lost_stage,
      color_hex: color_hex
    }
  end

  private

  def terminal_kinds_are_exclusive
    return unless is_won_stage? && is_lost_stage?

    errors.add(:is_won_stage, 'cannot be a won stage and a lost stage at the same time')
  end
end
