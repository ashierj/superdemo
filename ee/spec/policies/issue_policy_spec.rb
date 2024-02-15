# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePolicy, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:support_bot) { Users::Internal.support_bot }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:authorizer) { instance_double(::Gitlab::Llm::FeatureAuthorizer) }

  subject { described_class.new(user, issue) }

  before do
    allow(::Gitlab::Llm::FeatureAuthorizer).to receive(:new).and_return(authorizer)
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end

  describe 'summarize_notes' do
    context "when feature is authorized" do
      before do
        allow(authorizer).to receive(:allowed?).and_return(true)
      end

      context 'when user can read issue' do
        before do
          project.add_guest(user)
        end

        it { is_expected.to be_allowed(:summarize_notes) }
      end

      context 'when user cannot read issue' do
        it { is_expected.to be_disallowed(:summarize_notes) }
      end
    end

    context "when feature is not authorized" do
      before do
        project.add_guest(user)
        allow(authorizer).to receive(:allowed?).and_return(false)
      end

      it { is_expected.to be_disallowed(:summarize_notes) }
    end
  end

  describe 'admin_issue_relation' do
    let(:non_member) { user }
    let_it_be(:group) { create(:group, :public) }
    let_it_be_with_reload(:group_issue) { create(:issue, :group_level, namespace: group) }
    let_it_be(:public_project) { create(:project, :public, group: group) }
    let_it_be(:private_project) { create(:project, :private, group: group) }
    let_it_be(:public_issue) { create(:issue, project: public_project) }
    let_it_be(:private_issue) { create(:issue, project: private_project) }

    before_all do
      group.add_guest(guest)
      group.add_reporter(reporter)
    end

    it 'does not allow non-members to admin_issue_relation' do
      expect(permissions(non_member, group_issue)).to be_disallowed(:admin_issue_relation)
      expect(permissions(non_member, private_issue)).to be_disallowed(:admin_issue_relation)
      expect(permissions(non_member, public_issue)).to be_disallowed(:admin_issue_relation)
    end

    it 'allow guest to admin_issue_relation' do
      expect(permissions(guest, group_issue)).to be_allowed(:admin_issue_relation)
      expect(permissions(guest, private_issue)).to be_allowed(:admin_issue_relation)
      expect(permissions(guest, public_issue)).to be_allowed(:admin_issue_relation)
    end

    context 'when issue is confidential' do
      let_it_be(:confidential_issue) { create(:issue, :confidential, project: public_project) }

      it 'does not allow guest to admin_issue_relation' do
        expect(permissions(guest, confidential_issue)).to be_disallowed(:admin_issue_relation)
      end

      it 'allow reporter to admin_issue_relation' do
        expect(permissions(reporter, confidential_issue)).to be_allowed(:admin_issue_relation)
      end
    end

    context 'when user is support bot and service desk is enabled' do
      before do
        allow(::Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)
        allow(::Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
        allow_next_found_instance_of(Project) do |instance|
          allow(instance).to receive(:service_desk_enabled?).and_return(true)
        end
      end

      it 'allows support_bot to admin_issue_relation' do
        expect(permissions(support_bot, group_issue)).to be_allowed(:admin_issue_relation)
        expect(permissions(support_bot, public_issue)).to be_allowed(:admin_issue_relation)
        expect(permissions(support_bot, private_issue)).to be_allowed(:admin_issue_relation)
      end
    end

    context 'when user is support bot and service desk is disabled' do
      it 'does not allow support_bot to admin_issue_relation' do
        expect(permissions(support_bot, group_issue)).to be_disallowed(:admin_issue_relation)
        expect(permissions(support_bot, public_issue)).to be_disallowed(:admin_issue_relation)
        expect(permissions(support_bot, private_issue)).to be_disallowed(:admin_issue_relation)
      end
    end

    context 'when epic_relations_for_non_members feature flag is disabled' do
      before do
        stub_feature_flags(epic_relations_for_non_members: false)
      end

      it 'allows non-members to admin_issue_relation in public projects' do
        expect(permissions(non_member, public_issue)).to be_allowed(:admin_issue_relation)
      end

      it 'does not allow non-members to admin_issue_relation in private projects' do
        expect(permissions(non_member, private_issue)).to be_disallowed(:admin_issue_relation)
      end

      it 'allows guest to admin_issue_relation' do
        expect(permissions(guest, public_issue)).to be_allowed(:admin_issue_relation)
        expect(permissions(guest, private_issue)).to be_allowed(:admin_issue_relation)
      end
    end
  end
end
