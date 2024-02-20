# frozen_string_literal: true

FactoryBot.define do
  factory :member_role do
    namespace { association(:group) }
    base_access_level { Gitlab::Access::DEVELOPER }

    trait(:developer) { base_access_level { Gitlab::Access::DEVELOPER } }
    trait(:maintainer) { base_access_level { Gitlab::Access::MAINTAINER } }
    trait(:reporter) { base_access_level { Gitlab::Access::REPORTER } }
    trait(:guest) { base_access_level { Gitlab::Access::GUEST } }

    trait :admin_merge_request do
      admin_merge_request { true }
    end

    trait :admin_vulnerability do
      admin_vulnerability { true }
      read_vulnerability { true }
    end

    # this trait can be used only for self-managed
    trait(:instance) { namespace { nil } }
  end
end
