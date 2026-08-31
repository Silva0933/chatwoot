class Api::V1::Accounts::Kanban::TasksController < Api::V1::Accounts::BaseController
  before_action :fetch_task, except: [:index, :create]
  before_action :check_authorization

  def index
    @tasks = policy_scope(Current.account.kanban_tasks)
             .includes(:contact, :assigned_agent, :inbox, :stage, conversation: :inbox)
    @tasks = @tasks.where(kanban_pipeline_id: params[:pipeline_id]) if params[:pipeline_id].present?
    @tasks = @tasks.where(kanban_stage_id: params[:stage_id]) if params[:stage_id].present?
    @tasks = @tasks.where(assigned_agent_id: params[:assigned_agent_id]) if params[:assigned_agent_id].present?
  end

  def show; end

  def create
    @task = Current.account.kanban_tasks.create!(permitted_params.merge(stage_entered_at: Time.zone.now))
    render :show
  end

  def update
    @task.update!(permitted_params.except(:kanban_stage_id, :position))
    render :show
  end

  def move
    target_stage = Current.account.kanban_stages.find(params[:stage_id])
    @task = Kanban::MoveTaskService.new(
      task: @task,
      target_stage: target_stage,
      target_position: params[:position]
    ).perform
    render :show
  end

  def destroy
    @task.destroy!
    head :ok
  end

  private

  def fetch_task
    @task = Current.account.kanban_tasks.find(params[:id])
  end

  def check_authorization
    authorize(@task || Kanban::Task)
  end

  def permitted_params
    params.require(:task).permit(
      :kanban_pipeline_id, :kanban_stage_id, :conversation_id, :contact_id,
      :assigned_agent_id, :inbox_id, :title, :priority, :due_date, :position
    )
  end
end
