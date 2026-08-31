# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_automation, class: 'Kanban::Automation' do
    account
    pipeline { association :kanban_pipeline, account: account }
  end
end
