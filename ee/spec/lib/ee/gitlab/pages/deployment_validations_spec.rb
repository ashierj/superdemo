# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Pages::DeploymentValidations, feature_category: :pages do
  let_it_be(:group) { create(:group, :nested, max_pages_size: 200) }
  let_it_be(:project) { create(:project, :repository, namespace: group, max_pages_size: 250) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit("HEAD").sha) }

  let(:build_options) { {} }
  let(:build) { create(:ci_build, ref: "HEAD", name: 'pages', pipeline: pipeline, options: build_options) }

  let(:file) { fixture_file_upload("spec/fixtures/pages.zip") }
  let(:metafile) { fixture_file_upload("spec/fixtures/pages.zip.meta") }

  let(:metadata) do
    instance_double(
      ::Gitlab::Ci::Build::Artifacts::Metadata::Entry,
      entries: [],
      total_size: 50.megabyte
    )
  end

  subject(:validations) { described_class.new(project, build) }

  before do
    stub_pages_setting(enabled: true)
    create(:ci_job_artifact, :archive, :correct_checksum, file: file, job: build)
    create(:ci_job_artifact, :metadata, file: metafile, job: build)

    allow(build)
      .to receive(:artifacts_metadata_entry)
        .and_return(metadata)
  end

  shared_examples "valid pages deployment" do
    specify do
      expect(validations).to be_valid
    end
  end

  shared_examples "invalid pages deployment" do |message:|
    specify do
      expect(validations).not_to be_valid
      expect(validations.errors.full_messages).to include(message)
    end
  end

  describe "maximum pages artifacts size" do
    context "when pages_size_limit feature is available" do
      before do
        stub_licensed_features(pages_size_limit: true)
      end

      context "when size is below the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(249.megabyte)
        end

        include_examples "valid pages deployment"
      end

      context "when size is above the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(251.megabyte)
        end

        include_examples "invalid pages deployment",
          message: "artifacts for pages are too large: 263192576"
      end
    end

    context "when pages_size_limit feature is not available" do
      before do
        stub_licensed_features(pages_size_limit: false)
      end

      context "when size is below the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(99.megabyte)
        end

        include_examples "valid pages deployment"
      end

      context "when size is above the limit" do
        before do
          allow(metadata).to receive(:total_size).and_return(101.megabyte)
        end

        include_examples "invalid pages deployment",
          message: "artifacts for pages are too large: 105906176"
      end
    end
  end
end
