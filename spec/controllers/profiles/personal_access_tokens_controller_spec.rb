# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PersonalAccessTokensController do
  let(:access_token_user) { create(:user) }
  let(:token_attributes) { attributes_for(:personal_access_token) }

  before do
    sign_in(access_token_user)
  end

  describe '#create' do
    def created_token
      PersonalAccessToken.order(:created_at).last
    end

    it "allows creation of a token with scopes" do
      name = 'My PAT'
      scopes = %w[api read_user]

      post :create, params: { personal_access_token: token_attributes.merge(scopes: scopes, name: name) }

      expect(created_token).not_to be_nil
      expect(created_token.name).to eq(name)
      expect(created_token.scopes).to eq(scopes)
      expect(PersonalAccessToken.active).to include(created_token)
    end

    it "allows creation of a token with an expiry date" do
      expires_at = 5.days.from_now.to_date

      post :create, params: { personal_access_token: token_attributes.merge(expires_at: expires_at) }

      expect(created_token).not_to be_nil
      expect(created_token.expires_at).to eq(expires_at)
    end

    it_behaves_like "#create access token" do
      let(:url) { :create }
    end
  end

  describe 'GET /-/profile/personal_access_tokens' do
    let(:get_access_tokens) do
      get :index
      response
    end

    subject(:get_access_tokens_with_page) do
      get :index, params: { page: 1 }
      response
    end

    it_behaves_like 'GET access tokens are paginated and ordered'
  end

  describe '#index' do
    let!(:active_personal_access_token) { create(:personal_access_token, user: access_token_user) }

    before do
      # Impersonation and inactive personal tokens are ignored
      create(:personal_access_token, :impersonation, user: access_token_user)
      create(:personal_access_token, :revoked, user: access_token_user)
      get :index
    end

    it "only includes details of the active personal access token" do
      active_personal_access_tokens_detail =
        ::PersonalAccessTokenSerializer.new.represent([active_personal_access_token])

      expect(assigns(:active_access_tokens).to_json).to eq(active_personal_access_tokens_detail.to_json)
    end

    it "sets PAT name and scopes" do
      name = 'My PAT'
      scopes = 'api,read_user'

      get :index, params: { name: name, scopes: scopes }

      expect(assigns(:personal_access_token)).to have_attributes(
        name: eq(name),
        scopes: contain_exactly(:api, :read_user)
      )
    end

    it 'returns tokens for json format' do
      get :index, params: { format: :json }

      expect(json_response.count).to eq(1)
    end
  end
end
