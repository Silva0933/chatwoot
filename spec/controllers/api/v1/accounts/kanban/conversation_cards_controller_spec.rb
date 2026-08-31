require 'rails_helper'

RSpec.describe 'Kanban Conversation Cards API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let!(:first_stage) { create(:kanban_stage, account: account, pipeline: pipeline, name: 'Novo contato', position: 0) }
  let!(:scheduled_stage) { create(:kanban_stage, account: account, pipeline: pipeline, name: 'Agendado', position: 1) }
  let!(:task) do
    create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage, conversation: conversation)
  end
  let(:base_url) { "/api/v1/accounts/#{account.id}/kanban/conversation_cards/#{conversation.id}" }

  describe 'GET /api/v1/accounts/:account_id/kanban/conversation_cards/:conversation_id' do
    it 'returns unauthorized for an unauthenticated user' do
      get base_url, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the card with its stage name' do
      get base_url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['stage_name']).to eq('Novo contato')
      expect(response.parsed_body['pipeline_name']).to eq(pipeline.name)
    end

    it 'returns not found when the conversation has no card' do
      other = create(:conversation, account: account, inbox: inbox)

      get "/api/v1/accounts/#{account.id}/kanban/conversation_cards/#{other.id}",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/kanban/conversation_cards/:conversation_id/move' do
    it 'moves the card to the named stage' do
      post "#{base_url}/move", params: { stage: 'Agendado' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(task.reload.kanban_stage_id).to eq(scheduled_stage.id)
    end

    # An agent that drops the accent or the capital should still land the move,
    # otherwise the funnel silently stops reflecting reality.
    it 'matches the stage name without accents or case' do
      post "#{base_url}/move", params: { stage: 'novo CONTATO' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(task.reload.stage.name).to eq('Novo contato')
    end

    it 'answers an unknown stage with the list of valid ones' do
      post "#{base_url}/move", params: { stage: 'Agendamento solicitado' },
                               headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['valid_stages']).to contain_exactly('Novo contato', 'Agendado')
      expect(task.reload.kanban_stage_id).to eq(first_stage.id)
    end

    it 'records the transition so the metrics see it' do
      expect do
        post "#{base_url}/move", params: { stage: 'Agendado' }, headers: agent.create_new_auth_token, as: :json
      end.to change(Kanban::TaskTransition, :count).by(1)
    end
  end
end
