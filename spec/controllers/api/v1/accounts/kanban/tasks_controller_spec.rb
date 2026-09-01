require 'rails_helper'

RSpec.describe 'Kanban Tasks API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let!(:stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 0) }
  let(:base_url) { "/api/v1/accounts/#{account.id}/kanban/tasks" }

  describe 'GET /api/v1/accounts/:account_id/kanban/tasks' do
    let!(:task) do
      create(:kanban_task, account: account, pipeline: pipeline, stage: stage, conversation: conversation)
    end

    it 'returns unauthorized for an unauthenticated user' do
      get base_url, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    # An administrator returns from the policy scope before it builds the pipeline
    # subquery, so every board this endpoint served was served to an administrator
    # and the 500 an agent got went unseen.
    it 'loads the board for an agent' do
      get base_url, params: { pipeline_id: pipeline.id }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].length).to eq(1)
    end

    it 'hides a funnel the agent is not a member of' do
      other_pipeline = create(:kanban_pipeline, account: account)
      other_stage = create(:kanban_stage, account: account, pipeline: other_pipeline, position: 0)
      create(:kanban_task, account: account, pipeline: other_pipeline, stage: other_stage)
      other_pipeline.pipeline_members.create!(user: create(:user, account: account, role: :agent))

      get base_url, headers: agent.create_new_auth_token, as: :json

      pipeline_ids = response.parsed_body['payload'].pluck('pipeline_id')
      expect(pipeline_ids).to all(eq(pipeline.id))
    end

    # The card falls back to the conversation for what it is about, and the newest
    # message is the one that says where the conversation stands.
    it 'previews the last message of the conversation' do
      create(:message, account: account, inbox: inbox, conversation: conversation, content: 'Bom dia')
      create(:message, account: account, inbox: inbox, conversation: conversation, content: 'Queria saber o valor da limpeza')

      get base_url, params: { pipeline_id: pipeline.id }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].first['last_message']).to eq('Queria saber o valor da limpeza')
    end

    # "Conversation was marked resolved by ..." describes the board, not the
    # patient, and it would bury the message that does say something.
    it 'skips activity messages in the preview' do
      create(:message, account: account, inbox: inbox, conversation: conversation, content: 'Queria remarcar')
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       content: 'Conversation was marked resolved', message_type: :activity)

      get base_url, params: { pipeline_id: pipeline.id }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].first['last_message']).to eq('Queria remarcar')
    end

    it 'returns a null preview for a card with no conversation' do
      task.update!(conversation: nil)

      get base_url, params: { pipeline_id: pipeline.id }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].first['last_message']).to be_nil
    end

    # One DISTINCT ON pass, not one query per card: the board loads the whole
    # funnel at once, so a preview per card is how a board with a hundred cards
    # turns into a hundred queries.
    it 'previews every conversation in a single query' do
      create(:message, account: account, inbox: inbox, conversation: conversation, content: 'Primeiro')

      other_conversation = create(:conversation, account: account, inbox: inbox)
      create(:kanban_task, account: account, pipeline: pipeline, stage: stage, conversation: other_conversation)
      create(:message, account: account, inbox: inbox, conversation: other_conversation, content: 'Segundo')

      preview_queries = 0
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        preview_queries += 1 if payload[:sql].include?('DISTINCT ON (conversation_id)')
      end

      get base_url, params: { pipeline_id: pipeline.id }, headers: agent.create_new_auth_token, as: :json

      ActiveSupport::Notifications.unsubscribe(subscriber)

      previews = response.parsed_body['payload'].map { |card| card['last_message'] }
      expect(previews).to contain_exactly('Primeiro', 'Segundo')
      expect(preview_queries).to eq(1)
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/kanban/tasks/:id' do
    let!(:task) { create(:kanban_task, account: account, pipeline: pipeline, stage: stage) }

    # A summary written by hand outranks the message preview, which is the whole
    # point of having somewhere to write it.
    it 'stores the summary' do
      patch "#{base_url}/#{task.id}",
            params: { task: { summary: 'Retorno cardiologia, confirmar convênio' } },
            headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(task.reload.summary).to eq('Retorno cardiologia, confirmar convênio')
      expect(response.parsed_body['summary']).to eq('Retorno cardiologia, confirmar convênio')
    end
  end
end
