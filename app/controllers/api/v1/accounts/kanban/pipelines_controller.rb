class Api::V1::Accounts::Kanban::PipelinesController < Api::V1::Accounts::BaseController
  include Events::Types

  before_action :fetch_pipeline, except: [:index, :create, :templates]
  before_action :check_authorization

  def index
    @pipelines = policy_scope(Current.account.kanban_pipelines).includes(:stages)
    seed_default_pipeline if @pipelines.empty?
  end

  def show; end

  # The funnel templates live in Ruby so the seed and the API agree on them;
  # serving them keeps the "new pipeline" screen from re-declaring the same list.
  def templates
    @templates = Kanban::Templates::TEMPLATES
  end

  def metrics
    @metrics = Kanban::MetricsService.new(pipeline: @pipeline, since: params[:since]).perform
    render json: @metrics
  end

  def create
    @pipeline = Kanban::BuildPipelineService.new(account: Current.account, params: permitted_params).perform
    render :show
  end

  # The PRD describes this endpoint as updating "name, stages and automations", so
  # it accepts nested stages even though each also has a resource of its own. They
  # go through SaveStageService rather than a nested attributes assignment, because
  # promoting a won stage has to demote the incumbent in the same transaction.
  def update
    ActiveRecord::Base.transaction do
      @pipeline.update!(permitted_params.slice(:name, :description, :is_active, :position))
      update_stages if permitted_params[:stages].present?
    end
    Rails.configuration.dispatcher.dispatch(KANBAN_PIPELINE_UPDATED, Time.zone.now, pipeline: @pipeline.reload)
    render :show
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  private

  def update_stages
    permitted_params[:stages].each do |attrs|
      attrs = attrs.to_h.symbolize_keys
      stage = @pipeline.stages.find_by(id: attrs[:id])
      Kanban::SaveStageService.new(pipeline: @pipeline, params: attrs.except(:id), stage: stage).perform
    end
  end

  def fetch_pipeline
    @pipeline = Current.account.kanban_pipelines.includes(:stages).find(params[:id])
  end

  def check_authorization
    authorize(@pipeline || Kanban::Pipeline)
  end

  # First visit to the board should land on a usable clinic funnel rather than an
  # empty screen; re-running is harmless because it only fires when none exist.
  def seed_default_pipeline
    Kanban::BuildPipelineService.new(
      account: Current.account,
      params: { template_key: Kanban::Templates::DEFAULT_TEMPLATE_KEY }
    ).perform
    @pipelines = policy_scope(Current.account.kanban_pipelines.reload).includes(:stages)
  end

  def permitted_params
    params.require(:pipeline).permit(
      :name, :description, :is_active, :position, :template_key,
      stages: [:id, :name, :color_hex, :is_won_stage, :is_lost_stage, :position]
    )
  end
end
