class Api::V1::Accounts::Kanban::TasksController < Api::V1::Accounts::BaseController
  include Events::Types

  before_action :fetch_task, except: [:index, :create]
  before_action :check_authorization

  def index
    @tasks = policy_scope(Current.account.kanban_tasks)
             .includes(:contact, :assigned_agent, :inbox, :stage, conversation: :inbox)
    @tasks = @tasks.where(kanban_pipeline_id: params[:pipeline_id]) if params[:pipeline_id].present?
    @tasks = @tasks.where(kanban_stage_id: params[:stage_id]) if params[:stage_id].present?
    @tasks = @tasks.where(assigned_agent_id: params[:assigned_agent_id]) if params[:assigned_agent_id].present?
    @tasks = @tasks.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?

    @message_previews = message_previews_for(@tasks)
  end

  def show; end

  def create
    pipeline = Current.account.kanban_pipelines.find(permitted_params[:kanban_pipeline_id])
    @task = Kanban::CreateTaskService.new(pipeline: pipeline, params: permitted_params).perform
    render :show
  end

  def update
    @task.update!(permitted_params.except(:kanban_stage_id, :position))
    Rails.configuration.dispatcher.dispatch(KANBAN_TASK_UPDATED, Time.zone.now, task: @task)
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
    payload = @task.push_event_data
    @task.destroy!
    Rails.configuration.dispatcher.dispatch(KANBAN_TASK_DELETED, Time.zone.now, task_data: payload, account: Current.account)
    head :ok
  end

  private

  # The board loads every card in the funnel at once, so asking each conversation
  # for its own last message would be one query per card. DISTINCT ON picks the
  # newest row per conversation in a single pass — Postgres-only, which this app
  # already is.
  #
  # non_activity_messages carries a reorder of its own, so the ordering here has
  # to be a reorder too: DISTINCT ON requires the ORDER BY to lead with the
  # distinct expression.
  def message_previews_for(tasks)
    conversation_ids = tasks.filter_map(&:conversation_id).uniq
    return {} if conversation_ids.blank?

    Message.where(conversation_id: conversation_ids)
           .non_activity_messages
           .where.not(content: [nil, ''])
           .select('DISTINCT ON (conversation_id) conversation_id, content')
           .reorder('conversation_id, created_at DESC, id DESC')
           .to_h { |message| [message.conversation_id, message.content.to_s.squish.truncate(160)] }
  end

  def fetch_task
    @task = Current.account.kanban_tasks.find(params[:id])
  end

  def check_authorization
    authorize(@task || Kanban::Task)
  end

  def permitted_params
    params.require(:task).permit(
      :kanban_pipeline_id, :kanban_stage_id, :conversation_id, :contact_id,
      :assigned_agent_id, :inbox_id, :title, :summary, :priority, :due_date, :position,
      :value_cents, :loss_reason,
      metadata: {}
    )
  end
end
