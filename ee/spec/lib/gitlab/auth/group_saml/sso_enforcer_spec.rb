# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::SsoEnforcer, feature_category: :system_access do
  let(:saml_provider) { build_stubbed(:saml_provider, enforced_sso: true) }
  let(:user) { nil }
  let(:session) { {} }

  before do
    stub_licensed_features(group_saml: true)
  end

  around do |example|
    Gitlab::Session.with_session(session) do
      example.run
    end
  end

  subject { described_class.new(saml_provider, user: user) }

  describe '#update_session' do
    it 'stores that a session is active for the given provider' do
      expect { subject.update_session }.to change { session[:active_group_sso_sign_ins] }
    end

    it 'stores the current time for later comparison', :freeze_time do
      subject.update_session

      expect(session[:active_group_sso_sign_ins][saml_provider.id]).to eq DateTime.now
    end
  end

  describe '#active_session?' do
    it 'returns false if nothing has been stored' do
      expect(subject).not_to be_active_session
    end

    it 'returns true if a sign in has been recorded' do
      subject.update_session

      expect(subject).to be_active_session
    end

    it 'returns false if the sign in predates the session timeout' do
      subject.update_session

      days_after_timeout = Gitlab::Auth::GroupSaml::SsoEnforcer::DEFAULT_SESSION_TIMEOUT + 2.days
      travel_to(days_after_timeout.from_now) do
        expect(subject).not_to be_active_session
      end
    end
  end

  describe '#access_restricted?' do
    context 'when sso enforcement is enabled' do
      context 'when there is no active saml session' do
        it 'returns true' do
          expect(subject).to be_access_restricted
        end
      end

      context 'when there is active saml session' do
        before do
          subject.update_session
        end

        it 'returns false' do
          expect(subject).not_to be_access_restricted
        end
      end

      context 'when user is an admin' do
        let(:user) { create(:user, :admin) }

        context 'when admin mode enabled', :enable_admin_mode do
          it 'returns false' do
            expect(subject).not_to be_access_restricted
          end
        end

        context 'when admin mode disabled' do
          it 'returns true' do
            expect(subject).to be_access_restricted
          end
        end
      end

      context 'when user is an auditor' do
        let(:user) { create(:user, :auditor) }

        it 'returns false' do
          expect(subject).not_to be_access_restricted
        end
      end
    end

    context 'when saml_provider is nil' do
      let(:saml_provider) { nil }

      it 'returns false' do
        expect(subject).not_to be_access_restricted
      end
    end

    context 'when sso enforcement is disabled' do
      let(:saml_provider) { build_stubbed(:saml_provider, enforced_sso: false) }

      it 'returns false' do
        expect(subject).not_to be_access_restricted
      end
    end

    context 'when saml_provider is disabled' do
      let(:saml_provider) { build_stubbed(:saml_provider, enforced_sso: true, enabled: false) }

      it 'returns false' do
        expect(subject).not_to be_access_restricted
      end
    end
  end

  describe '.access_restricted?' do
    context 'when SAML SSO is enabled for resource' do
      using RSpec::Parameterized::TableSyntax

      let(:saml_provider) { create(:saml_provider, enabled: true, enforced_sso: false) }
      let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
      let(:root_group) { saml_provider.group }
      let(:subgroup) { create(:group, parent: root_group) }
      let(:shared_group) { create(:group) }
      let(:project) { create(:project, group: subgroup) }
      let(:member_with_identity) { identity.user }
      let(:member_without_identity) { create(:user) }
      let(:member_project) { create(:user) }
      let(:member_subgroup) { create(:user) }
      let(:member_shared) { create(:user) }
      let(:non_member) { create(:user) }
      let(:not_signed_in_user) { nil }
      let(:deploy_token) { create(:deploy_token) }

      before do
        create(:group_group_link, shared_group: root_group, shared_with_group: shared_group)

        stub_licensed_features(minimal_access_role: true, group_saml: true)

        root_group.add_developer(member_with_identity)
        root_group.add_developer(member_without_identity)
        subgroup.add_developer(member_subgroup)
        project.add_developer(member_project)
        shared_group.add_developer(member_shared)
      end

      shared_examples 'SSO Enforced' do
        it 'returns true' do
          expect(described_class.access_restricted?(user: user, resource: resource)).to eq(true)
        end
      end

      shared_examples 'SSO Not enforced' do
        it 'returns false' do
          expect(described_class.access_restricted?(user: user, resource: resource)).to eq(false)
        end
      end

      # See https://docs.gitlab.com/ee/user/group/saml_sso/#sso-enforcement
      where(:resource, :resource_visibility_level, :enforced_sso?, :user, :user_is_resource_owner?, :user_with_saml_session?, :user_is_admin?, :enable_admin_mode?, :user_is_auditor?, :shared_examples) do
        # Project/Group visibility: Private; Enforce SSO setting: Off

        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        # Project/Group visibility: Private; Enforce SSO setting: On

        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        # Project/Group visibility: Public; Enforce SSO setting: Off

        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        ref(:root_group) | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        # Project/Group visibility: Public; Enforce SSO setting: On

        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | true  | ref(:member_shared) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_shared) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_shared) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_shared) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_shared) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_shared) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_shared) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_shared) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_shared) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_shared) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_shared) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_shared) | false | nil   | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | true  | ref(:member_project) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_project) | false | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_project) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_project) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_project) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_project) | false | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_project) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_project) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_project) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_project) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_project) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_project) | false | nil   | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | true  | ref(:member_subgroup) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_subgroup) | false | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_subgroup) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_subgroup) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_subgroup) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_subgroup) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_subgroup) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_subgroup) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_subgroup) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_subgroup) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_subgroup) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_subgroup) | false | nil   | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
      end

      with_them do
        context "when 'Enforce SSO-only authentication for web activity for this group' option is #{params[:enforced_sso?] ? 'enabled' : 'not enabled'}" do
          around do |example|
            session = {}

            # Deploy Tokens are considered sessionless
            session = nil if user.is_a?(DeployToken)

            Gitlab::Session.with_session(session) do
              example.run
            end
          end

          before do
            saml_provider.update!(enforced_sso: enforced_sso?)
          end

          context "when resource is #{params[:resource_visibility_level]}" do
            before do
              if resource.is_a?(Group) && resource_visibility_level == 'private'
                resource.descendants.update_all(visibility_level: Gitlab::VisibilityLevel.string_options[resource_visibility_level])
              end

              resource.update!(visibility_level: Gitlab::VisibilityLevel.string_options[resource_visibility_level])
            end

            context 'for user', enable_admin_mode: params[:enable_admin_mode?] do
              before do
                if user_is_resource_owner?
                  resource.root_ancestor.member(user).update_column(:access_level, Gitlab::Access::OWNER)
                end

                Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session if user_with_saml_session?

                user.update!(admin: true) if user_is_admin?
                user.update!(auditor: true) if user_is_auditor?
              end

              include_examples params[:shared_examples]
            end
          end
        end
      end
    end
  end

  describe '.access_restricted_groups' do
    let!(:restricted_group) { create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: true)) }
    let!(:restricted_subgroup) { create(:group, parent: restricted_group) }
    let!(:restricted_group2) do
      create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: true))
    end

    let!(:unrestricted_group) { create(:group) }
    let!(:unrestricted_subgroup) { create(:group, parent: unrestricted_group) }
    let!(:groups) { [restricted_subgroup, restricted_group2, unrestricted_group, unrestricted_subgroup] }

    it 'handles empty groups array' do
      expect(described_class.access_restricted_groups([])).to eq([])
    end

    it 'returns a list of SSO enforced root groups' do
      expect(described_class.access_restricted_groups(groups))
        .to match_array([restricted_group, restricted_group2])
    end

    it 'returns only unique root groups' do
      expect(described_class.access_restricted_groups(groups.push(restricted_group)))
        .to match_array([restricted_group, restricted_group2])
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        described_class.access_restricted_groups([restricted_group])
      end

      expect { described_class.access_restricted_groups(groups) }.not_to exceed_all_query_limit(control)
    end
  end
end
