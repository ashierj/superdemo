# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_source_package, class: 'Sbom::SourcePackage' do
    purl_type { 'deb' }
    name { 'perl' }
  end
end
