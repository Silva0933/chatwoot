require 'rails_helper'

RSpec.describe 'Kanban Pipeline Members API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/kanban/pipelines/#{pipeline.id}/members" }

  describe 'GET /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/members' do
    it 'returns unauthorized for an unauthenticated user' do
      get base_url, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists the members with their user' do
      pipeline.pipeline_members.create!(user: agent)

      get base_url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      body = response.parsed_body['payload']
      expect(body.length).to eq(1)
      expect(body.first['user']['name']).to eq(agent.name)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/members' do
    it 'refuses an agent' do
      post base_url, params: { user_id: agent.id }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'adds the agent to the pipeline' do
      post base_url, params: { user_id: agent.id }, headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(pipeline.members).to include(agent)
    end

    it 'is idempotent so a double click does not raise' do
      2.times do
        post base_url, params: { user_id: agent.id }, headers: administrator.create_new_auth_token, as: :json
      end

      expect(response).to have_http_status(:success)
      expect(pipeline.pipeline_members.count).to eq(1)
    end

    it 'refuses a user from another account' do
      outsider = create(:user, account: create(:account), role: :agent)

      post base_url, params: { user_id: outsider.id }, headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
      expect(pipeline.pipeline_members.count).to eq(0)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/members/:id' do
    it 'removes the agent from the pipeline' do
      pipeline.pipeline_members.create!(user: agent)

      delete "#{base_url}/#{agent.id}", headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(pipeline.reload.members).to be_empty
    end
  end

  describe 'visibility' do
    # PipelinePolicy::Scope hides a funnel from agents once it has members, so
    # adding the first one is what actually turns access control on.
    it 'hides the pipeline from a non-member agent once someone is added' do
      other_agent = create(:user, account: account, role: :agent)
      pipeline.pipeline_members.create!(user: other_agent)

      get "/api/v1/accounts/#{account.id}/kanban/pipelines",
          headers: agent.create_new_auth_token, as: :json

      names = response.parsed_body['payload'].map { |row| row['name'] }
      expect(names).not_to include(pipeline.name)
    end
  end
end
