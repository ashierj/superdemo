# frozen_string_literal: true

FactoryBot.modify do
  factory :issue do
    trait :published do
      after(:create) do |issue|
        issue.create_status_page_published_incident!
      end
    end

    trait :with_sla do
      issuable_sla
    end
  end
end

FactoryBot.define do
  factory :requirement, parent: :issue do
    association :work_item_type, :default, :requirement
  end
end

FactoryBot.define do
  factory :quality_test_case, parent: :issue do
    association :work_item_type, :default, :test_case
  end
end
