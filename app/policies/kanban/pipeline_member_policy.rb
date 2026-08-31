class Kanban::PipelineMemberPolicy < ApplicationPolicy
  # Membership decides who sees a funnel, so only an administrator changes it.
  # Agents may read the list to know who else works the board.
  def index?
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
end
