# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::ExportSerializers::OrganizationDependenciesService, feature_category: :dependency_management do
  let_it_be(:organization) { create(:organization) }
  let_it_be_with_reload(:project) { create(:project, organization: organization) }
  let_it_be(:export) { create(:dependency_list_export, project: nil, organization: organization) }

  let(:service_class) { described_class.new(export) }

  describe '#each' do
    subject(:dependencies) { service_class.enum_for(:each).to_a }

    let(:header) { CSV.generate_line(%w[Name Version Packager Location], force_quotes: true) }

    context 'when the organization does not have dependencies' do
      it { is_expected.to match_array(header) }
    end

    context 'when the organization has dependencies' do
      let_it_be(:bundler) { create(:sbom_component, :bundler) }
      let_it_be(:bundler_v1) { create(:sbom_component_version, component: bundler, version: "1.0.0") }

      let_it_be(:occurrence_1) do
        create(:sbom_occurrence, :mit, project: project, component: bundler, component_version: bundler_v1)
      end

      it 'includes each occurrence' do
        expect(dependencies).to match_array([
          header,
          CSV.generate_line([
            occurrence_1.component_name,
            occurrence_1.version,
            occurrence_1.package_manager,
            occurrence_1.location[:blob_path]
          ], force_quotes: true)
        ])
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new do
          service_class.enum_for(:each).to_a
        end

        create_list(:project, 3, organization: organization).each do |project|
          create(:sbom_occurrence, project: project, source: create(:sbom_source))
        end

        expect do
          service_class.enum_for(:each).to_a
        end.to issue_same_number_of_queries_as(control).or_fewer
      end
    end
  end

  describe '#filename' do
    let(:timestamp) { Time.current.utc.strftime('%FT%H%M') }

    subject { service_class.filename }

    it { is_expected.to eq("#{organization.to_param}_dependencies_#{timestamp}.csv") }
  end
end
