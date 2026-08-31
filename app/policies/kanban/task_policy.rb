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
    @account_user.administrator? || @account_user.agent?
  end

  def move?
    update?
  end

  def destroy?
    @account_user.administrator?
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
