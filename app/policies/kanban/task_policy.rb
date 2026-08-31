class Kanban::TaskPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    return true if @account_user.administrator?

    @account_user.agent? && !viewer_on_pipeline?
  end

  def move?
    update?
  end

  def destroy?
    @account_user.administrator?
  end

  private

  # kanban_pipeline_members.role exists so a funnel can have people who watch it
  # without moving anyone else's cards. Absence of a membership row is not viewer:
  # a funnel with no members is open to the whole team, which the settings screen
  # says out loud.
  def viewer_on_pipeline?
    return false unless @record.respond_to?(:kanban_pipeline_id)

    Kanban::PipelineMember.exists?(
      kanban_pipeline_id: @record.kanban_pipeline_id,
      user_id: @user.id,
      role: :viewer
    )
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope if @account_user.administrator?

      scope.where(kanban_pipeline_id: visible_pipeline_ids)
    end

    private

    def visible_pipeline_ids
      Kanban::PipelinePolicy::Scope.new(@user_context, @account.kanban_pipelines).resolve.select(:id)
    end
  end
end
