# The card endpoint an external automation can drive from a conversation alone.
#
# Everything else in this namespace is addressed by card id, which an AI agent
# answering a WhatsApp message does not have and should not have to look up. Here
# the conversation is the key, and the stage is named rather than numbered, so a
# caller works in the same terms as the person it is talking to.
class Api::V1::Accounts::Kanban::ConversationCardsController < Api::V1::Accounts::BaseController
  before_action :fetch_task
  before_action :check_authorization

  def show; end

  def move
    stage = matching_stage
    return render_unknown_stage if stage.blank?

    @task = Kanban::MoveTaskService.new(task: @task, target_stage: stage).perform
    render :show
  end

  private

  def fetch_task
    @task = Current.account.kanban_tasks
                   .includes(:stage, pipeline: :stages)
                   .find_by!(conversation_id: params[:conversation_id])
  end

  # Accent- and case-insensitive: a caller writing "agendado" means the same stage
  # as "Agendado", and an agent that loses the accent should not fail the move.
  def matching_stage
    wanted = normalize(params[:stage])
    return if wanted.blank?

    @task.pipeline.stages.find { |stage| normalize(stage.name) == wanted }
  end

  def normalize(value)
    I18n.transliterate(value.to_s).downcase.strip
  end

  # The valid names travel with the error so a caller that guessed wrong can fix
  # itself on the next call instead of guessing again.
  def render_unknown_stage
    render json: {
      error: I18n.t('errors.kanban.unknown_stage'),
      valid_stages: @task.pipeline.stages.map(&:name)
    }, status: :unprocessable_entity
  end

  def check_authorization
    authorize(@task)
  end
end
