# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_task, class: 'Kanban::Task' do
    account
    pipeline { association :kanban_pipeline, account: account }
    stage { association :kanban_stage, account: account, pipeline: pipeline }
    contact { association :contact, account: account }
    sequence(:title) { |n| "Card #{n}" }
    position { 0 }
  end
end
