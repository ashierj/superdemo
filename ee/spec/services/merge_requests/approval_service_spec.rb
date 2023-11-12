# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ApprovalService, feature_category: :code_review_workflow do
  describe '#execute' do
    let_it_be(:user) { create :user }
    let_it_be(:group) { create :group }
    let_it_be(:project) do
      create :project,
        :public,
        :repository,
        group: group,
        approvals_before_merge: 0,
        merge_requests_author_approval: true
    end

    let_it_be(:merge_request) { create :merge_request_with_diffs, source_project: project, reviewers: [user] }
    let(:enforced_sso) { false }

    subject(:service) { described_class.new(project: project, current_user: user) }

    before do
      stub_licensed_features(group_saml: true)
      create(:saml_provider, group: project.group, enforced_sso: enforced_sso, enabled: true)
    end

    before_all do
      project.add_developer(user)
    end

    def simulate_require_saml_auth_to_approve_mr_approval_setting(restricted: true)
      allow(::Gitlab::Auth::GroupSaml::SsoEnforcer).to(receive(:access_restricted?).and_return(restricted))
    end

    def simulate_saml_approval_in_time?(in_time:)
      allow_next_instance_of(::Gitlab::Auth::GroupSaml::SsoState) do |state|
        allow(state).to receive(:active_since?).and_return(in_time)
      end
    end

    context 'with invalid approval' do
      before do
        allow(merge_request.approvals).to receive(:new).and_return(double(save: false))
      end

      it 'does not reset approvals cache' do
        expect(merge_request).not_to receive(:reset_approval_cache!)

        service.execute(merge_request)
      end
    end

    context 'with valid approval' do
      it 'resets the cache for approvals' do
        expect(merge_request).to receive(:reset_approval_cache!)

        service.execute(merge_request)
      end
    end

    context 'when project requires force auth for approval' do
      before do
        project.update!(require_password_to_approve: true)
      end

      context 'when password not specified' do
        it 'does not update the approvals' do
          expect { service.execute(merge_request) }.not_to change { merge_request.approvals.size }
        end
      end

      context 'when incorrect password is specified' do
        let(:params) do
          { approval_password: 'incorrect' }
        end

        it 'does not update the approvals' do
          service_with_params = described_class.new(project: project, current_user: user, params: params)

          expect { service_with_params.execute(merge_request) }.not_to change { merge_request.approvals.size }
        end
      end

      context 'when correct password is specified' do
        let(:params) do
          { approval_password: user.password }
        end

        it 'approves the merge request' do
          service_with_params = described_class.new(project: project, current_user: user, params: params)

          expect { service_with_params.execute(merge_request) }.to change { merge_request.approvals.size }
        end

        context 'when SAML auth is required' do
          let(:enforced_sso) { true }

          it 'does not change approval count' do
            simulate_require_saml_auth_to_approve_mr_approval_setting

            service_with_params = described_class.new(project: project, current_user: user, params: params)

            expect { service_with_params.execute(merge_request) }.not_to change { merge_request.approvals.size }
          end
        end
      end
    end
  end
end
