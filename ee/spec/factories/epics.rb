# frozen_string_literal: true

FactoryBot.define do
  factory :epic, traits: [:has_internal_id] do
    title { generate(:title) }
    group
    author

    trait :use_fixed_dates do
      start_date { Date.new(2010, 1, 1) }
      start_date_fixed { Date.new(2010, 1, 1) }
      start_date_is_fixed { true }
      end_date { Date.new(2010, 1, 3) }
      due_date_fixed { Date.new(2010, 1, 3) }
      due_date_is_fixed { true }
    end

    trait :confidential do
      confidential { true }
    end

    trait :opened do
      state { :opened }
    end

    trait :closed do
      state { :closed }
      closed_at { Time.now }
    end

    factory :labeled_epic do
      transient do
        labels { [] }
      end

      after(:create) do |epic, evaluator|
        epic.update!(labels: evaluator.labels)
      end
    end

    trait :with_synced_work_item do
      work_item do
        association(:work_item,
          :epic,
          namespace: group,
          title: title,
          description: description,
          created_at: created_at,
          updated_at: updated_at,
          author: author,
          iid: iid,
          updated_by: updated_by,
          state: state,
          confidential: confidential
        )
      end

      after(:create) do |epic, _|
        epic.work_item.update!(iid: epic.iid, created_at: epic.created_at)
      end
    end
  end
end
