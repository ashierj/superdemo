# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_vulnerabilities, class: '::Sbom::Ingestion::Vulnerabilities' do
    pipeline factory: :ci_pipeline

    skip_create

    initialize_with do
      ::Sbom::Ingestion::Vulnerabilities.new(attributes[:pipeline])
    end
  end
end
