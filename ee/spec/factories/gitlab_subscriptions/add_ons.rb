# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_subscription_add_on, class: 'GitlabSubscriptions::AddOn' do
    name { GitlabSubscriptions::AddOn.names[:code_suggestions] }
    description { 'AddOn for code suggestion features' }

    trait :code_suggestions do
      name { GitlabSubscriptions::AddOn.names[:code_suggestions] }
    end

    trait :product_analytics do
      name { GitlabSubscriptions::AddOn.names[:product_analytics] }
      description { 'AddOn for product analytics features' }
    end
  end
end
