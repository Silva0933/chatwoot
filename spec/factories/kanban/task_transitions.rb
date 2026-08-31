# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_task_transition, class: 'Kanban::TaskTransition' do
    account
    pipeline { association :kanban_pipeline, account: account }
    task { association :kanban_task, account: account, pipeline: pipeline }
    to_stage_id { task.kanban_stage_id }
  end
end
