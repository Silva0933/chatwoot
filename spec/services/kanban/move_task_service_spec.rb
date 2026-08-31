require 'rails_helper'

RSpec.describe Kanban::MoveTaskService do
  let(:account) { create(:account) }
  let(:pipeline) { create(:kanban_pipeline, account: account) }
  let!(:first_stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 0) }
  let!(:won_stage) { create(:kanban_stage, :won, account: account, pipeline: pipeline, position: 1) }
  let(:task) { create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage) }

  describe '#perform' do
    it 'moves the card and resets the stage clock' do
      task.update!(stage_entered_at: 3.days.ago)

      described_class.new(task: task, target_stage: won_stage).perform

      expect(task.reload.kanban_stage_id).to eq(won_stage.id)
      expect(task.stage_entered_at).to be_within(5.seconds).of(Time.zone.now)
    end

    it 'logs the transition with the time spent in the previous stage' do
      task.update!(stage_entered_at: 2.hours.ago)

      described_class.new(task: task, target_stage: won_stage).perform

      transition = Kanban::TaskTransition.find_by(kanban_task_id: task.id)
      expect(transition.from_stage_id).to eq(first_stage.id)
      expect(transition.to_stage_id).to eq(won_stage.id)
      expect(transition.seconds_in_previous_stage).to be_within(60).of(2.hours.to_i)
    end

    it 'does not log a transition when the card only changes position' do
      create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage, position: 1)

      described_class.new(task: task, target_stage: first_stage, target_position: 1).perform

      expect(Kanban::TaskTransition.count).to eq(0)
    end

    it 'dispatches moved and won when the card reaches the won stage' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      described_class.new(task: task, target_stage: won_stage).perform

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with('kanban.task_moved', anything, hash_including(from_stage_id: first_stage.id))
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with('kanban.task_won', anything, hash_including(task: task))
    end

    it 'keeps positions contiguous in the stage the card left' do
      second = create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage, position: 1)
      third = create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage, position: 2)

      described_class.new(task: task, target_stage: won_stage).perform

      expect([second.reload.position, third.reload.position]).to eq([0, 1])
    end
  end
end
