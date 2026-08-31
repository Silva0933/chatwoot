require 'rails_helper'

RSpec.describe 'Kanban Automations API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/kanban/pipelines/#{pipeline.id}/automation" }

  describe 'GET /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/automation' do
    it 'returns unauthorized for an unauthenticated user' do
      get base_url, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates the automation row when the pipeline has none' do
      get base_url, headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(pipeline.reload.automation).to be_present
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/kanban/pipelines/:pipeline_id/automation' do
    let!(:automation) { create(:kanban_automation, account: account, pipeline: pipeline) }

    it 'refuses an agent' do
      patch base_url, params: { automation: { auto_create_on_conversation: false } },
                      headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'updates the flags' do
      patch base_url, params: { automation: { auto_create_on_conversation: false } },
                      headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(automation.reload.auto_create_on_conversation).to be(false)
    end

    it 'drops inbox ids that belong to another account' do
      own_inbox = create(:inbox, account: account)
      foreign_inbox = create(:inbox, account: create(:account))

      patch base_url, params: { automation: { target_inbox_ids: [own_inbox.id, foreign_inbox.id] } },
                      headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(automation.reload.target_inbox_ids).to eq([own_inbox.id])
    end
  end
end
