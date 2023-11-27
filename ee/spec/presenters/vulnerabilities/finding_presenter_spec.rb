# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingPresenter, feature_category: :vulnerability_management do
  let(:presenter) { described_class.new(occurrence) }
  let(:occurrence) do
    finding = build_stubbed(:vulnerabilities_finding)
    metadata = ::Gitlab::Json.parse(finding.raw_metadata)

    metadata['location'] = metadata['location'].merge(
      { 'blob_path' => '/group/project/-/blob/dfd.../maven/src/main/java/tests/App.java' }
    )

    finding.raw_metadata = metadata.to_json

    finding
  end

  describe '#title' do
    subject { presenter.title }

    it { is_expected.to eq occurrence.name }
  end

  describe '#blob_path' do
    subject { presenter.blob_path }

    context 'without a sha' do
      it { is_expected.to be_blank }
    end

    context 'with a sha' do
      before do
        occurrence.sha = 'abc'
      end

      it { is_expected.to include(occurrence.sha) }

      context 'without start_line or end_line' do
        before do
          allow(presenter).to receive(:location)
            .and_return({ 'file' => 'a.txt' })
        end

        it { is_expected.to end_with('a.txt') }
      end

      context 'with start_line only' do
        before do
          allow(presenter).to receive(:location)
            .and_return({ 'file' => 'a.txt', 'start_line' => 1 })
        end

        it { is_expected.to end_with('#L1') }
      end

      context 'with start_line and end_line' do
        before do
          allow(presenter).to receive(:location)
            .and_return({ 'file' => 'a.txt', 'start_line' => 1, 'end_line' => 2 })
        end

        it { is_expected.to end_with('#L1-2') }
      end

      context 'when start_line and end_line are the same' do
        before do
          allow(presenter).to receive(:location)
            .and_return({ 'file' => 'a.txt', 'start_line' => 1, 'end_line' => 1 })
        end

        it { is_expected.to end_with('#L1') }
      end

      context 'without file' do
        before do
          allow(presenter).to receive(:location)
            .and_return({ 'foo' => 123 })
        end

        it { is_expected.to be_blank }
      end

      context 'without location' do
        before do
          allow(presenter).to receive(:location)
            .and_return({})
        end

        it { is_expected.to be_blank }
      end
    end
  end

  describe '#links' do
    let(:link_name) { 'Cipher does not check for integrity first?' }
    let(:link_url) { 'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first' }

    subject(:links) { presenter.links }

    it 'transforms the links to hash with indifferent access', :aggregate_failures do
      expect(links.first['name']).to eq(link_name)
      expect(links.first[:name]).to eq(link_name)
      expect(links.first['url']).to eq(link_url)
      expect(links.first[:url]).to eq(link_url)
    end
  end

  describe '#location_text' do
    subject(:location_text) { presenter.location_text }

    it 'presents the name of the filename', :aggregate_failures do
      expect(location_text).to eq('maven/src/main/java/com/gitlab/security_products/tests/App.java:29')
    end
  end

  describe '#location_link' do
    subject(:location_link) { presenter.location_link }

    it 'produces a blob links for the respective file', :aggregate_failures do
      expect(location_link).to eq('http://localhost/group/project/-/blob/dfd.../maven/src/main/java/tests/App.java')
    end
  end
end
