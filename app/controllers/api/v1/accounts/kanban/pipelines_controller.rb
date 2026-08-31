class Api::V1::Accounts::Kanban::PipelinesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline, except: [:index, :create]
  before_action :check_authorization

  def index
    @pipelines = policy_scope(Current.account.kanban_pipelines).includes(:stages)
    seed_default_pipeline if @pipelines.empty?
  end

  def show; end

  def create
    @pipeline = Kanban::BuildPipelineService.new(account: Current.account, params: permitted_params).perform
    render :show
  end

  def update
    @pipeline.update!(permitted_params.slice(:name, :description, :is_active, :position))
    render :show
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  private

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
      stages: [:name, :color_hex, :is_won_stage, :is_lost_stage]
    )
  end
end
