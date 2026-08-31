require 'rails_helper'

RSpec.describe Kanban::MetricsService do
  let(:account) { create(:account) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let!(:first_stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 0) }
  let!(:second_stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 1) }
  let!(:won_stage) { create(:kanban_stage, :won, account: account, pipeline: pipeline, position: 2) }
  let!(:lost_stage) { create(:kanban_stage, :lost, account: account, pipeline: pipeline, position: 3) }

  def metrics_for(stage)
    described_class.new(pipeline: pipeline).perform[:stages].find { |row| row[:id] == stage.id }
  end

  describe '#perform' do
    it 'counts the cards sitting in each stage' do
      create_list(:kanban_task, 2, account: account, pipeline: pipeline, stage: first_stage)
      create(:kanban_task, account: account, pipeline: pipeline, stage: second_stage)

      expect(metrics_for(first_stage)[:card_count]).to eq(2)
      expect(metrics_for(second_stage)[:card_count]).to eq(1)
    end

    it 'reports the share of cards that moved to the next stage' do
      task = create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage)
      create(:kanban_task_transition, account: account, pipeline: pipeline, task: task,
                                      from_stage_id: first_stage.id, to_stage_id: second_stage.id)
      create(:kanban_task_transition, account: account, pipeline: pipeline, task: task,
                                      from_stage_id: first_stage.id, to_stage_id: lost_stage.id)

      expect(metrics_for(first_stage)[:passage_rate]).to eq(50.0)
    end

    it 'leaves the passage rate empty when nothing has left the stage yet' do
      expect(metrics_for(first_stage)[:passage_rate]).to be_nil
    end

    it 'averages the time of cards that left together with the ones still waiting' do
      task = create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage,
                                  stage_entered_at: 100.seconds.ago)
      create(:kanban_task_transition, account: account, pipeline: pipeline, task: task,
                                      from_stage_id: first_stage.id, to_stage_id: second_stage.id,
                                      seconds_in_previous_stage: 300)

      expect(metrics_for(first_stage)[:average_seconds_in_stage]).to be_within(10).of(200)
    end

    it 'computes the win rate over closed cards only' do
      create(:kanban_task, account: account, pipeline: pipeline, stage: won_stage)
      create(:kanban_task, account: account, pipeline: pipeline, stage: lost_stage)
      create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage)

      totals = described_class.new(pipeline: pipeline).perform[:totals]

      expect(totals[:card_count]).to eq(3)
      expect(totals[:win_rate]).to eq(50.0)
    end
  end
end
