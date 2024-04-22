# frozen_string_literal: true

require 'spec_helper'
require_relative './config_shared_examples'

RSpec.describe Elastic::Latest::IssueConfig, feature_category: :global_search do
  describe '.settings' do
    it_behaves_like 'config settings return correct values'
  end

  describe '.mappings' do
    it 'returns config' do
      expect(described_class.mapping).to be_a(Elasticsearch::Model::Indexing::Mappings)
    end

    context 'for vector fields' do
      before do
        skip 'vectors are not supported' unless Gitlab::Elastic::Helper.default.vectors_supported?(:elasticsearch)
      end

      it 'includes vector fields' do
        mappings = described_class.mapping.to_hash
        expect(mappings[:properties].keys).to include(:embedding, :embedding_version)
      end
    end
  end
end
