# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::GitGuardian::Client, feature_category: :source_code_management do
  include FakeBlobHelpers

  let_it_be(:project) { build(:project) }
  let_it_be(:guardian_url) { 'https://api.gitguardian.com/v1/multiscan' }
  let_it_be(:token) { 'test-token' }

  let(:file_paths) { [] }
  let(:request_body) { [] }

  let(:stubbed_response) do
    # see doc https://api.gitguardian.com/docs#operation/multiple_scan to know more about the response structure
    file_paths.map do |_|
      {
        policy_break_count: 0,
        policies: [
          "Filename",
          "File extensions",
          "Secrets detection"
        ],
        policy_breaks: []
      }
    end.to_json
  end

  let(:blobs) { file_paths.map { |path| fake_blob(path: path) } }

  let(:status) { 200 }

  let(:stub_guardian_request) do
    stub_request(:post, guardian_url).with(
      body: request_body.to_json,
      headers: { 'Content-Type' => 'application/json', Authorization: "Token #{token}" }
    ).to_return(
      status: status,
      body: stubbed_response
    )
  end

  subject(:client) { described_class.new(token) }

  context 'without credentials' do
    let(:token) { '' }
    let!(:guardian_api_request) { stub_guardian_request }

    it 'raises a config error' do
      expect { client }.to raise_error(::Gitlab::GitGuardian::Client::ConfigError)
      expect(guardian_api_request).not_to have_been_requested
    end
  end

  context 'with credential' do
    let!(:guardian_api_request) { stub_guardian_request }
    let(:client_response) { client.execute(blobs) }

    context 'with no blobs' do
      let(:blobs) { [] }

      it 'returns an empty array' do
        expect(client_response).to eq []
        expect(guardian_api_request).not_to have_been_requested
      end
    end

    context 'when a blob without path' do
      let(:blobs) { [fake_blob(path: nil)] }
      let(:request_body) { [{ document: 'foo' }] }

      it 'returns an empty array' do
        expect(client_response).to eq []
        expect(guardian_api_request).to have_been_requested
      end
    end

    context 'with blobs without policy breaks' do
      let(:file_paths) { %w[README.md test_path/file.md test.yml] }

      let(:request_body) do
        [
          { document: 'foo', filename: 'README.md' },
          { document: 'foo', filename: 'file.md' },
          { document: 'foo', filename: 'test.yml' }
        ]
      end

      it 'returns an empty array' do
        expect(client_response).to eq []
        expect(guardian_api_request).to have_been_requested
      end
    end

    context 'with errors' do
      let(:file_paths) { %w[test_path/file.md lib/.env] }

      let(:request_body) do
        [
          { document: 'foo', filename: 'file.md' },
          { document: 'foo', filename: '.env' }
        ]
      end

      context 'when an API respond with an error' do
        # see doc https://api.gitguardian.com/docs#operation/multiple_scan to know more about possible error responses
        let(:status) { 403 }

        let(:stubbed_response) { nil }

        it 'raises a request error' do
          expect { client_response }.to raise_error(::Gitlab::GitGuardian::Client::RequestError)
          expect(guardian_api_request).to have_been_requested
        end
      end

      context 'when API response is malformed' do
        let(:stubbed_response) { '{fsde' }

        it 'raises a JSON error' do
          expect { client_response }.to raise_error(::Gitlab::GitGuardian::Client::Error, 'invalid response format')
          expect(guardian_api_request).to have_been_requested
        end
      end
    end

    context 'with policy breaking blobs' do
      let(:file_paths) { %w[test_path/file.md lib/.env] }

      let(:request_body) do
        [
          { document: 'foo', filename: 'file.md' },
          { document: 'foo', filename: '.env' }
        ]
      end

      let(:stubbed_response) do
        # see doc https://api.gitguardian.com/docs#operation/multiple_scan to know more about the response structure
        [
          {
            policy_break_count: 0,
            policies: [
              "Filename",
              "File extensions",
              "Secrets detection"
            ],
            policy_breaks: []
          },
          {
            policy_break_count: 2,
            policies: [
              "Filename",
              "File extensions",
              "Secrets detection"
            ],
            policy_breaks: [
              {
                type: ".env",
                policy: "Filenames",
                matches: [
                  {
                    type: "filename",
                    match: ".env"
                  }
                ]
              },
              {
                type: "Basic Auth String",
                policy: "Secrets detection",
                validity: "cannot_check",
                matches: [
                  {
                    type: "username",
                    match: "jen_barber",
                    index_start: 52,
                    index_end: 61,
                    line_start: 2,
                    line_end: 2
                  }
                ]
              }
            ]
          }
        ].to_json
      end

      it 'returns appropriate error messages' do
        expect(client_response).to eq [
          "Filenames policy violated at 'lib/.env' for filename '.env'",
          "Secrets detection policy violated at 'lib/.env' for username 'jen_barber'"
        ]
        expect(guardian_api_request).to have_been_requested
      end
    end
  end
end
