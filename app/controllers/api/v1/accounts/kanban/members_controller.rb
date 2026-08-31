class Api::V1::Accounts::Kanban::MembersController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline
  before_action :check_authorization

  def index
    @members = @pipeline.pipeline_members.includes(:user)
  end

  # Agents are looked up through the account rather than trusted from the request,
  # so a user id from another account cannot be added to this funnel.
  def create
    user = Current.account.users.find(params[:user_id])
    @member = @pipeline.pipeline_members.find_or_create_by!(user_id: user.id)
    render :show
  end

  def update
    @member = @pipeline.pipeline_members.find_by!(user_id: params[:id])
    @member.update!(role: params[:role])
    render :show
  end

  def destroy
    @pipeline.pipeline_members.find_by!(user_id: params[:id]).destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def check_authorization
    authorize(Kanban::PipelineMember)
  end
end
