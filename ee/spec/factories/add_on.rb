# frozen_string_literal: true

FactoryBot.define do
  factory :add_on, class: 'GitlabSubscriptions::AddOn' do
    name { GitlabSubscriptions::AddOn.names[:code_suggestions] }
    description { 'AddOn for code suggestion features' }
  end
end
