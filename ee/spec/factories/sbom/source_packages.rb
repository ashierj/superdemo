# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_source_package, class: 'Sbom::SourcePackage' do
    purl_type { 'deb' }
    sequence(:name) { |n| "component-#{n}" }
  end
end
