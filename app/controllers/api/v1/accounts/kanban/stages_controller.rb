class Api::V1::Accounts::Kanban::StagesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline
  before_action :fetch_stage, only: [:update, :destroy]
  before_action :check_authorization

  def create
    @stage = Kanban::SaveStageService.new(pipeline: @pipeline, params: permitted_params).perform
    render :show
  end

  def update
    @stage = Kanban::SaveStageService.new(pipeline: @pipeline, params: permitted_params, stage: @stage).perform
    render :show
  end

  def destroy
    Kanban::DestroyStageService.new(stage: @stage, fallback_stage: fallback_stage).perform
    head :ok
  rescue Kanban::DestroyStageService::StageNotEmptyError
    render json: { error: I18n.t('errors.kanban.stage_not_empty') }, status: :unprocessable_entity
  rescue Kanban::DestroyStageService::LastStageError
    render json: { error: I18n.t('errors.kanban.last_stage') }, status: :unprocessable_entity
  end

  def reorder
    @pipeline = Kanban::ReorderStagesService.new(pipeline: @pipeline, stage_ids: params[:stage_ids]).perform
    render 'api/v1/accounts/kanban/pipelines/show'
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.kanban_pipelines.find(params[:pipeline_id])
  end

  def fetch_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def fallback_stage
    return if params[:move_tasks_to_stage_id].blank?

    @pipeline.stages.find_by(id: params[:move_tasks_to_stage_id])
  end

  def check_authorization
    authorize(@stage || Kanban::Stage)
  end

  def permitted_params
    params.require(:stage).permit(:name, :color_hex, :is_won_stage, :is_lost_stage, :position)
  end
end
