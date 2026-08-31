class Kanban::PipelinePolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  class Scope < ApplicationPolicy::Scope
    # Administrators see every pipeline; agents only the ones they are a member of,
    # unless the pipeline has no members yet (a freshly seeded board is visible to all).
    def resolve
      return scope if @account_user.administrator?

      scope.left_joins(:pipeline_members)
           .where(kanban_pipeline_members: { user_id: [@user.id, nil] })
           .distinct
    end
  end
end
