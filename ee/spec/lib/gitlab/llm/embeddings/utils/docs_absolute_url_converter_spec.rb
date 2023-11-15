# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Embeddings::Utils::DocsAbsoluteUrlConverter, feature_category: :duo_chat do
  describe '.convert' do
    before do
      allow(Gitlab.config.gitlab).to receive(:url).and_return('https://gitlab.com')
    end

    context 'when content contains relative URLs' do
      let(:base_url) { "http://localhost:3001/help/user/project/repository/forking_workflow" }
      let(:content) { 'Got o the [namespace](../../namespace/index.md)' }

      subject { described_class.convert(content, base_url) }

      it { is_expected.to eq(%{Got o the [namespace](https://gitlab.com/help/user/namespace/index.html)}) }
    end

    context 'when content is empty' do
      let(:base_url) { "http://localhost:3001/help/user/project/repository/forking_workflow" }
      let(:content) { '' }

      subject { described_class.convert(content, base_url) }

      it { is_expected.to eq('') }
    end

    context 'when content is nil' do
      let(:base_url) { "http://localhost:3001/help/user/project/repository/forking_workflow" }
      let(:content) { nil }

      subject { described_class.convert(content, base_url) }

      it { is_expected.to be_nil }
    end
  end
end
