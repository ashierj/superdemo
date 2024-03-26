# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::CodeSuggestionsAccessToken, feature_category: :code_suggestions do
  subject { described_class.new(token).as_json }

  let_it_be(:token) do
    Gitlab::CloudConnector::SelfIssuedToken.new(
      audience: 'gitlab-ai-gateway', subject: 'ABC-123', scopes: [:code_suggestions]
    )
  end

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(:access_token, :expires_in, :created_at)
  end
end
