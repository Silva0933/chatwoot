# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_pipeline, class: 'Kanban::Pipeline' do
    account
    sequence(:name) { |n| "Pipeline #{n}" }
    description { 'A funnel' }
    is_active { true }
    position { 0 }
  end
end
