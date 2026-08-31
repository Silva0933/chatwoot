require 'rails_helper'

RSpec.describe Kanban::PipelineRoundRobinService do
  let(:account) { create(:account) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let(:first_agent) { create(:user, account: account, role: :agent) }
  let(:second_agent) { create(:user, account: account, role: :agent) }

  describe '#next_agent_id' do
    it 'returns nothing when the funnel has no members' do
      expect(described_class.new(pipeline: pipeline).next_agent_id).to be_nil
    end

    it 'alternates between the members instead of repeating one' do
      pipeline.pipeline_members.create!(user: first_agent)
      pipeline.pipeline_members.create!(user: second_agent)

      picks = Array.new(4) { described_class.new(pipeline: pipeline).next_agent_id }

      expect(picks.uniq.sort).to eq([first_agent.id, second_agent.id].sort)
      expect(picks[0]).not_to eq(picks[1])
      expect(picks[0]).to eq(picks[2])
    end

    it 'rebuilds the queue when the membership changes' do
      pipeline.pipeline_members.create!(user: first_agent)
      described_class.new(pipeline: pipeline).next_agent_id

      pipeline.pipeline_members.create!(user: second_agent)
      picks = Array.new(2) { described_class.new(pipeline: pipeline).next_agent_id }

      expect(picks.uniq.sort).to eq([first_agent.id, second_agent.id].sort)
    end
  end
end
