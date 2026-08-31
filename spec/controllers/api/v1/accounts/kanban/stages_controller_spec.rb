require 'rails_helper'

RSpec.describe 'Kanban Stages API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/kanban/pipelines/#{pipeline.id}/stages" }

  describe 'POST /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/stages' do
    it 'returns unauthorized for an unauthenticated user' do
      post base_url, params: { stage: { name: 'Proposta' } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'refuses an agent' do
      post base_url, params: { stage: { name: 'Proposta' } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates the stage for an administrator' do
      post base_url, params: { stage: { name: 'Proposta', color_hex: '#123456' } },
                     headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['name']).to eq('Proposta')
      expect(pipeline.stages.pluck(:name)).to include('Proposta')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/stages/reorder' do
    it 'applies the given order' do
      first = create(:kanban_stage, account: account, pipeline: pipeline, position: 0)
      second = create(:kanban_stage, account: account, pipeline: pipeline, position: 1)

      post "#{base_url}/reorder", params: { stage_ids: [second.id, first.id] },
                                  headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['stages'].map { |stage| stage['id'] }).to eq([second.id, first.id])
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/stages/:id' do
    let!(:stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 0) }
    let!(:fallback_stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 1) }

    it 'moves the cards to the given stage' do
      task = create(:kanban_task, account: account, pipeline: pipeline, stage: stage)

      delete "#{base_url}/#{stage.id}", params: { move_tasks_to_stage_id: fallback_stage.id },
                                        headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(task.reload.kanban_stage_id).to eq(fallback_stage.id)
    end

    it 'returns an error when the stage still holds cards and no destination is given' do
      create(:kanban_task, account: account, pipeline: pipeline, stage: stage)

      delete "#{base_url}/#{stage.id}", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to be_present
      expect(Kanban::Stage.exists?(stage.id)).to be(true)
    end
  end
end
