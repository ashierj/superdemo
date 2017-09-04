require 'spec_helper'

describe Gitlab::Auth do
  let(:gl_auth) { described_class }

  describe 'constants' do
    it 'API_SCOPES contains all scopes for API access' do
      expect(subject::API_SCOPES).to eq [:api, :read_user]
    end

    it 'OPENID_SCOPES contains all scopes for OpenID Connect' do
      expect(subject::OPENID_SCOPES).to eq [:openid]
    end

    it 'DEFAULT_SCOPES contains all default scopes' do
      expect(subject::DEFAULT_SCOPES).to eq [:api]
    end

    it 'OPTIONAL_SCOPES contains all non-default scopes' do
      expect(subject::OPTIONAL_SCOPES).to eq %i[read_user read_registry openid]
    end

    it 'REGISTRY_SCOPES contains all registry related scopes' do
      expect(subject::REGISTRY_SCOPES).to eq %i[read_registry]
    end
  end

  describe 'find_for_git_client' do
    context 'build token' do
      subject { gl_auth.find_for_git_client('gitlab-ci-token', build.token, project: project, ip: 'ip') }

      context 'for running build' do
        let!(:build) { create(:ci_build, :running) }
        let(:project) { build.project }

        before do
          expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: 'gitlab-ci-token')
        end

        it 'recognises user-less build' do
          expect(subject).to eq(Gitlab::Auth::Result.new(nil, build.project, :ci, build_authentication_abilities))
        end

        it 'recognises user token' do
          build.update(user: create(:user))

          expect(subject).to eq(Gitlab::Auth::Result.new(build.user, build.project, :build, build_authentication_abilities))
        end
      end

      (HasStatus::AVAILABLE_STATUSES - ['running']).each do |build_status|
        context "for #{build_status} build" do
          let!(:build) { create(:ci_build, status: build_status) }
          let(:project) { build.project }

          before do
            expect(gl_auth).to receive(:rate_limit!).with('ip', success: false, login: 'gitlab-ci-token')
          end

          it 'denies authentication' do
            expect(subject).to eq(Gitlab::Auth::Result.new)
          end
        end
      end
    end

    it 'recognizes other ci services' do
      project = create(:project)
      project.create_drone_ci_service(active: true)
      project.drone_ci_service.update(token: 'token')

      expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: 'drone-ci-token')
      expect(gl_auth.find_for_git_client('drone-ci-token', 'token', project: project, ip: 'ip')).to eq(Gitlab::Auth::Result.new(nil, project, :ci, build_authentication_abilities))
    end

    it 'recognizes master passwords' do
      user = create(:user, password: 'password')

      expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: user.username)
      expect(gl_auth.find_for_git_client(user.username, 'password', project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, full_authentication_abilities))
    end

    include_examples 'user login operation with unique ip limit' do
      let(:user) { create(:user, password: 'password') }

      def operation
        expect(gl_auth.find_for_git_client(user.username, 'password', project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, full_authentication_abilities))
      end
    end

    context 'while using LFS authenticate' do
      it 'recognizes user lfs tokens' do
        user = create(:user)
        token = Gitlab::LfsToken.new(user).token

        expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: user.username)
        expect(gl_auth.find_for_git_client(user.username, token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :lfs_token, full_authentication_abilities))
      end

      it 'recognizes deploy key lfs tokens' do
        key = create(:deploy_key)
        token = Gitlab::LfsToken.new(key).token

        expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: "lfs+deploy-key-#{key.id}")
        expect(gl_auth.find_for_git_client("lfs+deploy-key-#{key.id}", token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(key, nil, :lfs_deploy_token, read_authentication_abilities))
      end

      it 'does not try password auth before oauth' do
        user = create(:user)
        token = Gitlab::LfsToken.new(user).token

        expect(gl_auth).not_to receive(:find_with_user_password)

        gl_auth.find_for_git_client(user.username, token, project: nil, ip: 'ip')
      end
    end

    context 'while using OAuth tokens as passwords' do
      let(:user) { create(:user) }
      let(:token_w_api_scope) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'api') }
      let(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }

      it 'succeeds for OAuth tokens with the `api` scope' do
        expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: 'oauth2')
        expect(gl_auth.find_for_git_client("oauth2", token_w_api_scope.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(user, nil, :oauth, full_authentication_abilities))
      end

      it 'fails for OAuth tokens with other scopes' do
        token = Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'read_user')

        expect(gl_auth).to receive(:rate_limit!).with('ip', success: false, login: 'oauth2')
        expect(gl_auth.find_for_git_client("oauth2", token.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(nil, nil))
      end

      it 'does not try password auth before oauth' do
        expect(gl_auth).not_to receive(:find_with_user_password)

        gl_auth.find_for_git_client("oauth2", token_w_api_scope.token, project: nil, ip: 'ip')
      end
    end

    context 'while using personal access tokens as passwords' do
      it 'succeeds for personal access tokens with the `api` scope' do
        personal_access_token = create(:personal_access_token, scopes: ['api'])

        expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: '')
        expect(gl_auth.find_for_git_client('', personal_access_token.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(personal_access_token.user, nil, :personal_token, full_authentication_abilities))
      end

      it 'succeeds for personal access tokens with the `read_registry` scope' do
        personal_access_token = create(:personal_access_token, scopes: ['read_registry'])

        expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: '')
        expect(gl_auth.find_for_git_client('', personal_access_token.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(personal_access_token.user, nil, :personal_token, [:read_container_image]))
      end

      it 'succeeds if it is an impersonation token' do
        impersonation_token = create(:personal_access_token, :impersonation, scopes: ['api'])

        expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: '')
        expect(gl_auth.find_for_git_client('', impersonation_token.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(impersonation_token.user, nil, :personal_token, full_authentication_abilities))
      end

      it 'limits abilities based on scope' do
        personal_access_token = create(:personal_access_token, scopes: ['read_user'])

        expect(gl_auth).to receive(:rate_limit!).with('ip', success: true, login: '')
        expect(gl_auth.find_for_git_client('', personal_access_token.token, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(personal_access_token.user, nil, :personal_token, []))
      end

      it 'fails if password is nil' do
        expect(gl_auth).to receive(:rate_limit!).with('ip', success: false, login: '')
        expect(gl_auth.find_for_git_client('', nil, project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new(nil, nil))
      end
    end

    context 'while using regular user and password' do
      it 'falls through lfs authentication' do
        user = create(
          :user,
          username: 'normal_user',
          password: 'my-secret'
        )

        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, ip: 'ip'))
          .to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, full_authentication_abilities))
      end

      it 'falls through oauth authentication when the username is oauth2' do
        user = create(
          :user,
          username: 'oauth2',
          password: 'my-secret'
        )

        expect(gl_auth.find_for_git_client(user.username, user.password, project: nil, ip: 'ip'))
          .to eq(Gitlab::Auth::Result.new(user, nil, :gitlab_or_ldap, full_authentication_abilities))
      end
    end

    it 'returns double nil for invalid credentials' do
      login = 'foo'

      expect(gl_auth).to receive(:rate_limit!).with('ip', success: false, login: login)
      expect(gl_auth.find_for_git_client(login, 'bar', project: nil, ip: 'ip')).to eq(Gitlab::Auth::Result.new)
    end

    it 'throws an error suggesting user create a PAT when internal auth is disabled' do
      allow_any_instance_of(ApplicationSetting).to receive(:password_authentication_enabled?) { false }

      expect { gl_auth.find_for_git_client('foo', 'bar', project: nil, ip: 'ip') }.to raise_error(Gitlab::Auth::MissingPersonalTokenError)
    end
  end

  describe 'find_with_user_password' do
    let!(:user) do
      create(:user,
        username: username,
        password: password,
        password_confirmation: password)
    end
    let(:username) { 'John' }     # username isn't lowercase, test this
    let(:password) { 'my-secret' }

    it "finds user by valid login/password" do
      expect( gl_auth.find_with_user_password(username, password) ).to eql user
    end

    it 'finds user by valid email/password with case-insensitive email' do
      expect(gl_auth.find_with_user_password(user.email.upcase, password)).to eql user
    end

    it 'finds user by valid username/password with case-insensitive username' do
      expect(gl_auth.find_with_user_password(username.upcase, password)).to eql user
    end

    it "does not find user with invalid password" do
      password = 'wrong'
      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    it "does not find user with invalid login" do
      user = 'wrong'
      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    include_examples 'user login operation with unique ip limit' do
      def operation
        expect(gl_auth.find_with_user_password(username, password)).to eq(user)
      end
    end

    it "does not find user in blocked state" do
      user.block

      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    it "does not find user in ldap_blocked state" do
      user.ldap_block

      expect( gl_auth.find_with_user_password(username, password) ).not_to eql user
    end

    context "with ldap enabled" do
      before do
        allow(Gitlab::LDAP::Config).to receive(:enabled?).and_return(true)
      end

      it "tries to autheticate with db before ldap" do
        expect(Gitlab::LDAP::Authentication).not_to receive(:login)

        gl_auth.find_with_user_password(username, password)
      end

      it "uses ldap as fallback to for authentication" do
        expect(Gitlab::LDAP::Authentication).to receive(:login)

        gl_auth.find_with_user_password('ldap_user', 'password')
      end
    end
  end

  private

  def build_authentication_abilities
    [
      :read_project,
      :build_download_code,
      :build_read_container_image,
      :build_create_container_image
    ]
  end

  def read_authentication_abilities
    [
      :read_project,
      :download_code,
      :read_container_image
    ]
  end

  def full_authentication_abilities
    read_authentication_abilities + [
      :push_code,
      :create_container_image,
      :admin_container_image
    ]
  end
end
