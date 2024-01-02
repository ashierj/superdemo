# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyListSerializer do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { create(:user) }

  let(:ci_build) { create(:ee_ci_build, :success) }
  let(:dependencies) { [build(:dependency, :with_vulnerabilities, :with_licenses)] }

  let(:serializer) do
    described_class.new(project: project, user: user).represent(dependencies, build: ci_build)
  end

  before do
    stub_licensed_features(security_dashboard: true, license_scanning: true)
    stub_feature_flags(project_level_sbom_occurrences: false)
    project.add_developer(user)
  end

  describe "#to_json" do
    subject { serializer.to_json }

    it 'matches the schema' do
      is_expected.to match_schema('dependency_list', dir: 'ee')
    end

    context 'with project_level_sbom_occurrences enabled' do
      before do
        stub_feature_flags(project_level_sbom_occurrences: true)
      end

      it 'does not include vulnerabilities' do
        is_expected.not_to include('vulnerabilities')
      end

      %w[occurrence_id vulnerability_count].each do |json_attribute|
        it "includes #{json_attribute}" do
          is_expected.to include(json_attribute)
        end
      end
    end
  end
end
