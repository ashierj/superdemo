# frozen_string_literal: true

RSpec.shared_examples 'GET resource access tokens available' do
  let_it_be(:active_resource_access_token) { create(:personal_access_token, user: bot_user) }

  it 'retrieves active resource access tokens' do
    get_access_tokens

    token_entities = assigns(:active_resource_access_tokens)
    expect(token_entities.length).to eq(1)
    expect(token_entities[0][:name]).to eq(active_resource_access_token.name)
  end

  it 'lists all available scopes' do
    get_access_tokens

    expect(assigns(:scopes)).to eq(Gitlab::Auth.resource_bot_scopes)
  end

  it 'returns for json response' do
    get_access_tokens_json

    expect(json_response.count).to eq(1)
  end

  context "when access_tokens are paginated" do
    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      create(:personal_access_token, user: bot_user)
    end

    it "returns paginated response", :aggregate_failures do
      get_access_tokens_with_page
      expect(assigns(:active_resource_access_tokens).count).to eq(1)

      expect_header('X-Per-Page', '1')
      expect_header('X-Page', '1')
      expect_header('X-Next-Page', '2')
      expect_header('X-Total', '2')
    end
  end

  context "when access_token_pagination feature flag is disabled" do
    before do
      stub_feature_flags(access_token_pagination: false)
      create(:personal_access_token, user: bot_user)
    end

    it "returns all tokens in system" do
      get_access_tokens_with_page
      expect(assigns(:active_resource_access_tokens).count).to eq(2)
    end
  end

  context "as tokens returned are ordered" do
    let(:expires_1_day_from_now) { 1.day.from_now.to_date }
    let(:expires_2_day_from_now) { 2.days.from_now.to_date }

    before do
      create(:personal_access_token, user: bot_user, name: "Token1", expires_at: expires_1_day_from_now)
      create(:personal_access_token, user: bot_user, name: "Token2", expires_at: expires_2_day_from_now)
    end

    it "orders token list ascending on expires_at" do
      get_access_tokens

      first_token = assigns(:active_resource_access_tokens).first.as_json
      expect(first_token['name']).to eq("Token1")
      expect(first_token['expires_at']).to eq(expires_1_day_from_now.strftime("%Y-%m-%d"))
    end

    it "orders tokens on id in case token has same expires_at" do
      create(:personal_access_token, user: bot_user, name: "Token3", expires_at: expires_1_day_from_now)
      get_access_tokens

      first_token = assigns(:active_resource_access_tokens).first.as_json
      expect(first_token['name']).to eq("Token3")
      expect(first_token['expires_at']).to eq(expires_1_day_from_now.strftime("%Y-%m-%d"))

      second_token = assigns(:active_resource_access_tokens).second.as_json
      expect(second_token['name']).to eq("Token1")
      expect(second_token['expires_at']).to eq(expires_1_day_from_now.strftime("%Y-%m-%d"))
    end
  end

  def expect_header(header_name, header_val)
    expect(response.headers[header_name]).to eq(header_val)
  end
end

RSpec.shared_examples 'POST resource access tokens available' do
  def created_token
    PersonalAccessToken.order(:created_at).last
  end

  it 'renders JSON with a token' do
    subject

    parsed_body = Gitlab::Json.parse(response.body)
    expect(parsed_body['new_token']).not_to be_blank
    expect(parsed_body['errors']).to be_blank
    expect(response).to have_gitlab_http_status(:success)
  end

  it 'creates resource access token' do
    access_level = access_token_params[:access_level] || Gitlab::Access::MAINTAINER
    subject

    expect(created_token.name).to eq(access_token_params[:name])
    expect(created_token.scopes).to eq(access_token_params[:scopes])
    expect(created_token.expires_at).to eq(access_token_params[:expires_at])
    expect(resource.member(created_token.user).access_level).to eq(access_level)
  end

  it 'creates project bot user' do
    subject

    expect(created_token.user).to be_project_bot
  end

  it { expect { subject }.to change { User.count }.by(1) }
  it { expect { subject }.to change { PersonalAccessToken.count }.by(1) }

  context 'when unsuccessful' do
    before do
      allow_next_instance_of(ResourceAccessTokens::CreateService) do |service|
        allow(service).to receive(:execute).and_return ServiceResponse.error(message: 'Failed!')
      end
    end

    it 'does not create the token' do
      expect { subject }.not_to change { PersonalAccessToken.count }
    end

    it 'does not add the project bot as a member' do
      expect { subject }.not_to change { Member.count }
    end

    it 'does not create the project bot user' do
      expect { subject }.not_to change { User.count }
    end

    it 'renders JSON with an error' do
      subject

      parsed_body = Gitlab::Json.parse(response.body)
      expect(parsed_body['new_token']).to be_blank
      expect(parsed_body['errors']).to contain_exactly('Failed!')
      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end
end

RSpec.shared_examples 'PUT resource access tokens available' do
  it 'calls delete user worker' do
    expect(DeleteUserWorker).to receive(:perform_async).with(user.id, bot_user.id, skip_authorization: true)

    subject
  end

  it 'removes membership of bot user' do
    subject

    expect(resource.reload.bots).not_to include(bot_user)
  end

  context 'when user_destroy_with_limited_execution_time_worker is enabled' do
    it 'creates GhostUserMigration records to handle migration in a worker' do
      expect { subject }.to(
        change { Users::GhostUserMigration.count }.from(0).to(1))
    end
  end

  context 'when user_destroy_with_limited_execution_time_worker is disabled' do
    before do
      stub_feature_flags(user_destroy_with_limited_execution_time_worker: false)
    end

    it 'converts issuables of the bot user to ghost user' do
      issue = create(:issue, author: bot_user)

      subject

      expect(issue.reload.author.ghost?).to be true
    end

    it 'deletes project bot user' do
      subject

      expect(User.exists?(bot_user.id)).to be_falsy
    end
  end

  context 'when unsuccessful' do
    before do
      allow_next_instance_of(ResourceAccessTokens::RevokeService) do |service|
        allow(service).to receive(:execute).and_return ServiceResponse.error(message: 'Failed!')
      end
    end

    it 'shows a failure alert' do
      subject

      expect(flash[:alert]).to include("Could not revoke access token")
    end
  end
end
