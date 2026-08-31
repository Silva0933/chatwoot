class Kanban::PipelineRoundRobinService
  # AutoAssignment::InboxRoundRobinService takes an Inbox and reads inbox_members,
  # so it cannot be reused here: a funnel's rotation runs over its own
  # kanban_pipeline_members. The queue mechanics are the same — a Redis list that
  # is popped from the front and pushed to the back.
  pattr_initialize [:pipeline!]

  def next_agent_id
    reset_queue unless queue_matches_members?

    # Read from the tail and push back to the head, the same direction the inbox
    # rotation uses. Taking from the head instead would hand the queue straight
    # back to the agent who was just picked.
    agent_id = queue.last
    return if agent_id.blank?

    rotate(agent_id)
    agent_id.to_i
  end

  private

  # Members are the explicit access list from the PRD. A funnel nobody was added to
  # has no rotation to run, which is why this returns nothing rather than falling
  # back to every agent in the account.
  def member_ids
    @member_ids ||= pipeline.pipeline_members.pluck(:user_id)
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def queue_matches_members?
    queue.map(&:to_i).sort == member_ids.sort
  end

  def reset_queue
    ::Redis::Alfred.delete(round_robin_key)
    ::Redis::Alfred.lpush(round_robin_key, member_ids) if member_ids.any?
  end

  def rotate(agent_id)
    ::Redis::Alfred.lrem(round_robin_key, agent_id)
    ::Redis::Alfred.lpush(round_robin_key, agent_id)
  end

  def round_robin_key
    format(::Redis::Alfred::KANBAN_ROUND_ROBIN_AGENTS, pipeline_id: pipeline.id)
  end
end
