class Kanban::Task < ApplicationRecord
  include AccountCacheRevalidator

  self.table_name = 'kanban_tasks'

  belongs_to :account
  belongs_to :pipeline,
             class_name: 'Kanban::Pipeline',
             foreign_key: :kanban_pipeline_id,
             inverse_of: :tasks
  belongs_to :stage,
             class_name: 'Kanban::Stage',
             foreign_key: :kanban_stage_id,
             inverse_of: :tasks
  belongs_to :contact
  belongs_to :conversation, optional: true
  belongs_to :assigned_agent, class_name: 'User', optional: true
  belongs_to :inbox, optional: true

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, prefix: true

  validates :title, presence: true
  validate :stage_belongs_to_pipeline

  before_validation :set_stage_entered_at, on: :create
  before_save :reset_stage_entered_at, if: :kanban_stage_id_changed?

  default_scope { order(:position, :id) }

  scope :open, -> { joins(:stage).where(kanban_stages: { is_won_stage: false, is_lost_stage: false }) }

  def seconds_in_stage
    Time.zone.now - stage_entered_at
  end

  def overdue?
    due_date.present? && due_date.past?
  end

  def push_event_data
    {
      id: id,
      pipeline_id: kanban_pipeline_id,
      stage_id: kanban_stage_id,
      conversation_id: conversation_id,
      contact_id: contact_id,
      assigned_agent_id: assigned_agent_id,
      inbox_id: inbox_id,
      title: title,
      priority: priority,
      due_date: due_date,
      stage_entered_at: stage_entered_at,
      position: position
    }
  end

  private

  def set_stage_entered_at
    self.stage_entered_at ||= Time.zone.now
  end

  # The "time in stage" counter the board renders is derived from this column, so
  # it has to restart on every stage change, including ones made outside the move service.
  def reset_stage_entered_at
    self.stage_entered_at = Time.zone.now
  end

  def stage_belongs_to_pipeline
    return if kanban_stage_id.blank? || kanban_pipeline_id.blank?
    return if stage&.kanban_pipeline_id == kanban_pipeline_id

    errors.add(:kanban_stage_id, 'must belong to the same pipeline as the task')
  end
end
