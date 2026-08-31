require 'rails_helper'

RSpec.describe Kanban::DestroyStageService do
  let(:account) { create(:account) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  # Both eager: a lazy fallback_stage leaves the pipeline with a single stage, and
  # every example here would hit the last-stage guard instead of its own subject.
  let!(:stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 0) }
  let!(:fallback_stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 1) }

  describe '#perform' do
    it 'deletes an empty stage without needing a fallback' do
      described_class.new(stage: stage).perform

      expect(Kanban::Stage.exists?(stage.id)).to be(false)
    end

    it 'moves the cards to the fallback stage before deleting' do
      task = create(:kanban_task, account: account, pipeline: pipeline, stage: stage)

      described_class.new(stage: stage, fallback_stage: fallback_stage).perform

      expect(task.reload.kanban_stage_id).to eq(fallback_stage.id)
      expect(Kanban::Stage.exists?(stage.id)).to be(false)
    end

    it 'appends the moved cards after the ones already in the fallback stage' do
      create(:kanban_task, account: account, pipeline: pipeline, stage: fallback_stage, position: 0)
      moved = create(:kanban_task, account: account, pipeline: pipeline, stage: stage, position: 0)

      described_class.new(stage: stage, fallback_stage: fallback_stage).perform

      expect(moved.reload.position).to eq(1)
    end

    it 'refuses to delete the only stage a pipeline has' do
      fallback_stage.destroy!

      expect { described_class.new(stage: stage).perform }
        .to raise_error(described_class::LastStageError)
    end

    it 'refuses to delete a populated stage with no fallback' do
      create(:kanban_task, account: account, pipeline: pipeline, stage: stage)

      expect { described_class.new(stage: stage).perform }
        .to raise_error(described_class::StageNotEmptyError)
      expect(Kanban::Stage.exists?(stage.id)).to be(true)
    end
  end
end
