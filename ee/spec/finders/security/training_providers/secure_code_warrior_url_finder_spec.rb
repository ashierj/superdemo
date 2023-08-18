# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrainingProviders::SecureCodeWarriorUrlFinder do
  include ReactiveCachingHelpers

  let_it_be(:provider_name) { 'Secure Code Warrior' }
  let_it_be(:provider) { create(:security_training_provider, name: provider_name) }
  let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2, name: "cwe-2") }
  let_it_be(:dummy_url) { 'http://test.host/test' }
  let_it_be(:identifier_external_id) { "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]" }

  let(:finder) { described_class.new(identifier.project, provider, identifier_external_id) }

  describe '#execute' do
    context "when external_type is present in allowed list" do
      context 'when request fails' do
        before do
          synchronous_reactive_cache(finder)
          stub_request(:get, "http://test.host/test").and_raise(SocketError)
        end

        it 'returns nil' do
          expect(finder.calculate_reactive_cache(dummy_url)).to be_nil
        end
      end

      context 'when response is 404' do
        before do
          synchronous_reactive_cache(finder)
          stub_request(:get, "http://test.host/test")
            .to_return(
              status: 404,
              body: '{"name":"Not Found","message":"Mapping key not found","code":404}',
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'returns hash with nil url' do
          expect(finder.calculate_reactive_cache(dummy_url)).to eq({ url: nil })
        end
      end

      context 'when response is not nil' do
        let_it_be(:response) { { 'url' => dummy_url } }

        before do
          synchronous_reactive_cache(finder)
          stub_request(:get, "http://test.host/test")
            .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns content url hash' do
          expect(finder.calculate_reactive_cache(dummy_url)).to eq({ url: dummy_url })
        end
      end
    end

    context "when external_type is not present in allowed list" do
      let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'invalid type', external_id: "A1", name: "A1. Injection") }
      let_it_be(:identifier_external_id) { "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]" }

      it 'returns nil' do
        expect(finder.execute).to be_nil
      end
    end
  end

  describe '#full_url' do
    it 'returns full url path' do
      expect(finder.full_url).to eq('https://example.com?Id=gitlab&MappingKey=2&MappingList=cwe')
    end

    context "when identifier contains CWE-{number} format" do
      it 'returns full url path with proper mapping key' do
        expect(finder.full_url).to eq('https://example.com?Id=gitlab&MappingKey=2&MappingList=cwe')
      end
    end

    context "when identifier contains owasp identifier" do
      let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'owasp', external_id: "A1", name: "A1. Injection") }
      let_it_be(:identifier_external_id) { "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]" }

      it 'returns full url path with proper mapping key' do
        expect(finder.full_url).to eq("https://example.com?Id=gitlab&MappingKey=A1&MappingList=owasp-web-2017")
      end
    end

    context "when a language is provided" do
      let_it_be(:language) { 'ruby' }

      it 'returns full url path with the language parameter mapped' do
        expect(
          described_class.new(identifier.project, provider, identifier_external_id, language).full_url
        ).to eq("https://example.com?Id=gitlab&LanguageKey=#{language}&MappingKey=2&MappingList=cwe")
      end
    end
  end

  describe '#mapping_key' do
    context 'when owasp' do
      let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'owasp', external_id: "A1", name: "A1. Injection") }
      let_it_be(:identifier_external_id) { "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]" }

      it 'returns external_id' do
        expect(finder.mapping_key).to eq(identifier.external_id)
      end
    end

    context 'when cwe' do
      let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2, name: 'cwe-2') }
      let_it_be(:identifier_external_id) { "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]" }

      it 'returns parsed identifier name' do
        expect(finder.mapping_key).to eq(identifier.name.split('-').last)
      end
    end
  end

  describe '#mapping_list' do
    context 'when owasp' do
      let(:identifier) { create(:vulnerabilities_identifier, external_type: 'owasp', external_id: external_id, name: name) }
      let(:identifier_external_id) { "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]" }

      context 'when owasp-web-2017' do
        let(:external_id) { "A1" }
        let(:name) { "A1. Injection" }

        it 'returns proper owasp category' do
          expect(finder.mapping_list).to eq("owasp-web-2017")
        end
      end

      context 'when owasp-api-2019' do
        let(:external_id) { "API1" }
        let(:name) { "API1. Broken Object Level Authorization" }

        it 'returns proper owasp category' do
          expect(finder.mapping_list).to eq("owasp-api-2019")
        end
      end
    end

    context 'when cwe' do
      let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2, name: 'cwe-2') }
      let_it_be(:identifier_external_id) { "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]" }

      it 'returns parsed identifier name' do
        expect(finder.mapping_list).to eq(identifier.external_type)
      end
    end
  end

  describe '#allowed_identifier_list' do
    it 'returns allowed identifiers' do
      expect(finder.allowed_identifier_list).to match_array(%w[cwe owasp])
    end
  end
end
