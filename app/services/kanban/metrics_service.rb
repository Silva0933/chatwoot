class Kanban::MetricsService
  # The "X" of the PRD's F.L.U.X.O.: volume per stage, where cards are sitting too
  # long, and how many of them make it to the next stage.
  pattr_initialize [:pipeline!, :since]

  def perform
    {
      stages: stages.map { |stage| stage_metrics(stage) },
      totals: totals
    }
  end

  private

  def stages
    @stages ||= pipeline.stages.to_a
  end

  def since_time
    @since_time ||= since.presence ? Time.zone.parse(since.to_s) : 30.days.ago
  end

  def transitions
    @transitions ||= pipeline.task_transitions.where(created_at: since_time..).to_a
  end

  def open_tasks
    @open_tasks ||= pipeline.tasks.to_a
  end

  def stage_metrics(stage)
    current = open_tasks.select { |task| task.kanban_stage_id == stage.id }
    left = transitions.select { |transition| transition.from_stage_id == stage.id }

    {
      id: stage.id,
      name: stage.name,
      color_hex: stage.color_hex,
      is_won_stage: stage.is_won_stage,
      is_lost_stage: stage.is_lost_stage,
      card_count: current.length,
      entered_count: transitions.count { |transition| transition.to_stage_id == stage.id },
      # Cards that left this stage for the next one in the funnel, over every card
      # that left it at all. A stage people escape sideways from is the bottleneck.
      passage_rate: passage_rate(stage, left),
      average_seconds_in_stage: average_seconds(stage, current, left)
    }
  end

  def passage_rate(stage, left)
    return if left.empty?

    next_stage = stages[stages.index(stage) + 1]
    return if next_stage.blank?

    forward = left.count { |transition| transition.to_stage_id == next_stage.id }
    (forward.to_f / left.length * 100).round(1)
  end

  # Blends the cards that already moved on with the ones still waiting, so a column
  # where everything is stuck does not report a flattering average built only from
  # the few cards that escaped it.
  def average_seconds(stage, current, left)
    samples = left.filter_map(&:seconds_in_previous_stage)
    samples += current.map { |task| task.seconds_in_stage.to_i }
    return if samples.empty?

    (samples.sum / samples.length.to_f).round
  end

  def totals
    won_stage = pipeline.won_stage
    lost_stage = pipeline.lost_stage
    won = won_stage ? open_tasks.count { |task| task.kanban_stage_id == won_stage.id } : 0
    lost = lost_stage ? open_tasks.count { |task| task.kanban_stage_id == lost_stage.id } : 0
    closed = won + lost

    {
      card_count: open_tasks.length,
      won_count: won,
      lost_count: lost,
      win_rate: closed.zero? ? nil : (won.to_f / closed * 100).round(1)
    }
  end
end
