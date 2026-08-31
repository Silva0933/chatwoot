class Api::V1::Accounts::Kanban::AutomationsController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline
  before_action :fetch_automation
  before_action :check_authorization

  def show; end

  def update
    @automation.update!(permitted_params)
    render :show
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  # Pipelines built before the automation engine existed were backfilled, but a
  # pipeline restored from an old dump would still arrive without one. Creating it
  # on read keeps the settings screen from 404ing on an otherwise valid funnel.
  def fetch_automation
    @automation = @pipeline.automation || @pipeline.create_automation!(account_id: @pipeline.account_id)
  end

  def check_authorization
    authorize(@automation)
  end

  # Inbox ids are filtered against the account's own inboxes: an id from another
  # account would otherwise silently widen which conversations feed this funnel.
  def permitted_params
    permitted = params.require(:automation).permit(
      :auto_create_on_conversation, :auto_assign_task_to_agent, :auto_assign_conversation_to_agent,
      :auto_resolve_conversation_on_finish, :auto_win_task_on_resolve, :round_robin_assignment,
      target_inbox_ids: []
    )
    return permitted if permitted[:target_inbox_ids].blank?

    permitted.merge(target_inbox_ids: Current.account.inboxes.where(id: permitted[:target_inbox_ids]).pluck(:id))
  end
end
