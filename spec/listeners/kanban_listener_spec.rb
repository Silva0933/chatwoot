require 'rails_helper'

describe KanbanListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let!(:pipeline) { create(:kanban_pipeline, account: account) }
  let!(:first_stage) { create(:kanban_stage, account: account, pipeline: pipeline, position: 0) }
  let!(:won_stage) { create(:kanban_stage, :won, account: account, pipeline: pipeline, position: 1) }
  let!(:automation) { create(:kanban_automation, account: account, pipeline: pipeline) }

  describe '#conversation_created' do
    let(:event) { Events::Base.new(:'conversation.created', Time.zone.now, conversation: conversation) }

    it 'creates a card in the first stage' do
      listener.conversation_created(event)

      task = pipeline.tasks.last
      expect(task.kanban_stage_id).to eq(first_stage.id)
      expect(task.conversation_id).to eq(conversation.id)
      expect(task.contact_id).to eq(contact.id)
    end

    it 'does nothing when auto create is off' do
      automation.update!(auto_create_on_conversation: false)

      listener.conversation_created(event)

      expect(pipeline.tasks.count).to eq(0)
    end

    it 'skips a funnel that targets other inboxes' do
      automation.update!(target_inbox_ids: [create(:inbox, account: account).id])

      listener.conversation_created(event)

      expect(pipeline.tasks.count).to eq(0)
    end

    it 'does not create a second card when the conversation is reopened' do
      2.times { listener.conversation_created(event) }

      expect(pipeline.tasks.count).to eq(1)
    end

    it 'leaves an inactive pipeline alone' do
      pipeline.update!(is_active: false)

      listener.conversation_created(event)

      expect(pipeline.tasks.count).to eq(0)
    end
  end

  describe '#conversation_resolved' do
    let(:event) { Events::Base.new(:'conversation.resolved', Time.zone.now, conversation: conversation) }
    let!(:task) do
      create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage, conversation: conversation)
    end

    it 'moves the card to the won stage' do
      listener.conversation_resolved(event)

      expect(task.reload.kanban_stage_id).to eq(won_stage.id)
    end

    it 'does nothing when the automation is off' do
      automation.update!(auto_win_task_on_resolve: false)

      listener.conversation_resolved(event)

      expect(task.reload.kanban_stage_id).to eq(first_stage.id)
    end
  end

  describe '#conversation_updated' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let!(:task) do
      create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage, conversation: conversation)
    end

    # The listener runs through EventDispatcherJob, so it reads what changed from
    # the event payload rather than from the record's dirty tracking.
    it 'mirrors the assignee onto the card' do
      conversation.update!(assignee: agent)
      event = Events::Base.new(:'conversation.updated', Time.zone.now,
                               conversation: conversation, changed_attributes: { 'assignee_id' => [nil, agent.id] })

      listener.conversation_updated(event)

      expect(task.reload.assigned_agent_id).to eq(agent.id)
    end

    it 'ignores an update that did not touch the assignee' do
      conversation.update!(assignee: agent)
      event = Events::Base.new(:'conversation.updated', Time.zone.now,
                               conversation: conversation, changed_attributes: { 'status' => %w[open pending] })

      listener.conversation_updated(event)

      expect(task.reload.assigned_agent_id).to be_nil
    end
  end

  describe '#kanban_task_won' do
    let!(:task) do
      create(:kanban_task, account: account, pipeline: pipeline, stage: won_stage, conversation: conversation)
    end
    let(:event) { Events::Base.new(:'kanban.task_won', Time.zone.now, task: task) }

    it 'resolves the conversation' do
      listener.kanban_task_won(event)

      expect(conversation.reload.status).to eq('resolved')
    end

    it 'does nothing when the automation is off' do
      automation.update!(auto_resolve_conversation_on_finish: false)

      listener.kanban_task_won(event)

      expect(conversation.reload.status).not_to eq('resolved')
    end
  end

  describe '#kanban_task_updated' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let!(:task) do
      create(:kanban_task, account: account, pipeline: pipeline, stage: first_stage,
                           conversation: conversation, assigned_agent: agent)
    end
    let(:event) { Events::Base.new(:'kanban.task_updated', Time.zone.now, task: task) }

    it 'assigns the conversation to the card owner' do
      listener.kanban_task_updated(event)

      expect(conversation.reload.assignee_id).to eq(agent.id)
    end

    it 'does nothing when the automation is off' do
      automation.update!(auto_assign_conversation_to_agent: false)

      listener.kanban_task_updated(event)

      expect(conversation.reload.assignee_id).to be_nil
    end
  end
end
