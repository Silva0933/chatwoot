# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_stage, class: 'Kanban::Stage' do
    account
    pipeline { association :kanban_pipeline, account: account }
    sequence(:name) { |n| "Stage #{n}" }
    color_hex { '#4A86E8' }
    position { 0 }

    trait :won do
      is_won_stage { true }
    end

    trait :lost do
      is_lost_stage { true }
    end
  end
end
