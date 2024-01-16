# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::Embedding::GitlabDocumentation::CreateEmptyEmbeddingsRecordsWorker, feature_category: :duo_chat do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always

  describe '#perform' do
    shared_examples 'enqueing workers per file' do
      it 'enqueues worker per file' do
        expect(embeddings_per_doc_file_worker).to receive(:perform_async).with(
          Rails.root.join(described_class::DOC_DIRECTORY, "index.md").to_s, next_version
        ).once

        expect { perform }.not_to change { ::Embedding::Vertex::GitlabDocumentation.count }
      end

      it_behaves_like 'an idempotent worker' do
        before do
          allow(embeddings_per_doc_file_worker).to receive(:perform_async)
        end

        it 'creates no records' do
          expect { perform }.not_to change { ::Embedding::Vertex::GitlabDocumentation.count }
        end
      end
    end

    before do
      stub_const("#{described_class}::DOC_DIRECTORY", './ee/spec/fixtures/gitlab_documentation')
      allow(::Gitlab::Llm::Embeddings::Utils::DocsContentParser).to receive(:parse_and_split).and_return([item])
      allow(::Embedding::Vertex::GitlabDocumentation).to receive(:current_version).and_return(version)
    end

    let(:embeddings_per_doc_file_worker) { Llm::Embedding::GitlabDocumentation::CreateDbEmbeddingsPerDocFileWorker }
    let(:logger) { described_class.new.send(:logger) }
    let(:version) { 111 }
    let(:next_version) { version + 1 }
    let(:class_instance) { described_class.new }
    let(:item) do
      {
        content: "# Heading 1\n",
        metadata: { type: "reference", group: "Unknown", info: "Test Information", title: "Heading 1" },
        url: 'a.url'
      }
    end

    subject(:perform) { class_instance.perform }

    it 'does not enqueue any workers' do
      expect(embeddings_per_doc_file_worker).not_to receive(:perform_async)

      perform
    end

    describe 'checks' do
      using RSpec::Parameterized::TableSyntax

      where(:ai_global_switch_enabled, :vertex_embeddings_enabled, :feature_available) do
        false | false | false

        false | false | true
        false | true  | false
        true  | false | false

        false | true  | true
        true  | false | true
        true  | true  | false
      end

      with_them do
        before do
          stub_feature_flags(ai_global_switch: ai_global_switch_enabled)
          allow(Gitlab::Saas).to receive(:feature_available?).with(described_class::FEATURE_NAME).and_return(
            vertex_embeddings_enabled
          )
          allow(License).to receive(:feature_available?).with(:ai_chat).and_return(feature_available)
        end

        it 'does not create any records or enqueue any workers' do
          expect(embeddings_per_doc_file_worker).not_to receive(:perform_async)

          expect { perform }.not_to change { ::Embedding::Vertex::GitlabDocumentation.count }
        end
      end
    end

    context 'with the feature available' do
      before do
        allow(Gitlab::Saas).to receive(:feature_available?).with(described_class::FEATURE_NAME).and_return(true)
        allow(License).to receive(:feature_available?).with(:ai_chat).and_return(true)
      end

      context 'when no embeddings exist' do
        it_behaves_like 'enqueing workers per file'
      end

      context 'when embeddings exist' do
        let(:embeddings_model) { 'textembedding-gecko@002' }
        let(:model) { embeddings_model }
        let(:content) { File.read(File.join(described_class::DOC_DIRECTORY, "index.md")) }
        let(:md5sum) { OpenSSL::Digest::SHA256.hexdigest(content + model) }
        let(:metadata) { { source: '/ee/spec/fixtures/gitlab_documentation/index.md', md5sum: md5sum } }
        let!(:records) { create_list(:vertex_gitlab_documentation, 3, version: version, metadata: metadata) }

        before do
          stub_const('Gitlab::Llm::VertexAi::ModelConfigurations::TextEmbeddings::NAME', embeddings_model)
        end

        context 'when model and content match' do
          it_behaves_like 'an idempotent worker'
        end

        context 'when models differ' do
          let(:model) { 'textembedding-gecko@003' }

          it_behaves_like 'enqueing workers per file'
        end

        context 'when content differ' do
          let(:content) { 'new content' }

          it_behaves_like 'enqueing workers per file'
        end

        context 'when there are embeddings for non existent files' do
          let(:content) { File.read(File.join(described_class::DOC_DIRECTORY, "index.md")) }
          let(:md5sum2) { 'does not really matter' }
          let(:other_metadata) { { source: '/ee/spec/fixtures/gitlab_documentation/non_existent.md', md5sum: md5sum2 } }

          it 'removes embeddings for non-existent files' do
            create_list(:vertex_gitlab_documentation, 3, version: version, metadata: metadata)
            create_list(:vertex_gitlab_documentation, 2, version: version, metadata: other_metadata)

            expect { perform }.to change { ::Embedding::Vertex::GitlabDocumentation.count }.by(-2)
          end
        end
      end
    end
  end
end
