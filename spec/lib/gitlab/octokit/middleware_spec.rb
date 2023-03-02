# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Octokit::Middleware, feature_category: :importers do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }

  shared_examples 'Public URL' do
    it 'does not raise an error' do
      expect(app).to receive(:call).with(env)

      expect { middleware.call(env) }.not_to raise_error
    end
  end

  shared_examples 'Local URL' do
    it 'raises an error' do
      expect { middleware.call(env) }.to raise_error(Gitlab::UrlBlocker::BlockedUrlError)
    end
  end

  describe '#call' do
    context 'when the URL is a public URL' do
      let(:env) { { url: 'https://public-url.com' } }

      it_behaves_like 'Public URL'
    end

    context 'when the URL is a localhost address' do
      let(:env) { { url: 'http://127.0.0.1' } }

      context 'when localhost requests are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        it_behaves_like 'Local URL'
      end

      context 'when localhost requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it_behaves_like 'Public URL'
      end
    end

    context 'when the URL is a local network address' do
      let(:env) { { url: 'http://172.16.0.0' } }

      context 'when local network requests are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        it_behaves_like 'Local URL'
      end

      context 'when local network requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it_behaves_like 'Public URL'
      end
    end

    context 'when a non HTTP/HTTPS URL is provided' do
      let(:env) { { url: 'ssh://172.16.0.0' } }

      it 'raises an error' do
        expect { middleware.call(env) }.to raise_error(Gitlab::UrlBlocker::BlockedUrlError)
      end
    end
  end
end
