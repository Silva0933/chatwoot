require 'rails_helper'

RSpec.describe Kanban::SaveStageService do
  let(:account) { create(:account) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }

  describe '#perform' do
    it 'appends a new stage after the existing ones' do
      create(:kanban_stage, account: account, pipeline: pipeline, position: 0)
      create(:kanban_stage, account: account, pipeline: pipeline, position: 1)

      stage = described_class.new(pipeline: pipeline, params: { name: 'Proposta' }).perform

      expect(stage.position).to eq(2)
      expect(stage.account_id).to eq(account.id)
    end

    it 'demotes the previous won stage when another one is promoted' do
      incumbent = create(:kanban_stage, :won, account: account, pipeline: pipeline)
      challenger = create(:kanban_stage, account: account, pipeline: pipeline)

      described_class.new(pipeline: pipeline, params: { is_won_stage: true }, stage: challenger).perform

      expect(incumbent.reload.is_won_stage).to be(false)
      expect(challenger.reload.is_won_stage).to be(true)
    end

    it 'leaves another pipeline won stage alone' do
      other_pipeline = create(:kanban_pipeline, account: account)
      other_won = create(:kanban_stage, :won, account: account, pipeline: other_pipeline)
      stage = create(:kanban_stage, account: account, pipeline: pipeline)

      described_class.new(pipeline: pipeline, params: { is_won_stage: true }, stage: stage).perform

      expect(other_won.reload.is_won_stage).to be(true)
    end
  end
end
