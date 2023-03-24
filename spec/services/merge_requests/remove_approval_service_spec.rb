# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RemoveApprovalService, feature_category: :code_review_workflow do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let!(:existing_approval) { create(:approval, merge_request: merge_request) }

    subject(:service) { described_class.new(project: project, current_user: user) }

    def execute!
      service.execute(merge_request)
    end

    before do
      project.add_developer(user)
    end

    context 'with a user who has approved' do
      let!(:approval) { create(:approval, user: user, merge_request: merge_request) }
      let(:notification_service) { NotificationService.new }

      before do
        allow(service).to receive(:notification_service).and_return(notification_service)
      end

      it 'removes the approval' do
        expect { execute! }.to change { merge_request.approvals.size }.from(2).to(1)
      end

      it 'creates an unapproval note, triggers a web hook, and sends a notification' do
        expect(service).to receive(:execute_hooks).with(merge_request, 'unapproved')
        expect(SystemNoteService).to receive(:unapprove_mr)
        expect(notification_service).to receive_message_chain(:async, :unapprove_mr).with(merge_request, user)

        execute!
      end

      describe 'caching of approved SHAs', :clean_gitlab_redis_shared_state do
        let!(:cache_key) { approval.approved_sha_cache_key }

        it 'removes approved_sha_cache_key' do
          expect { execute! }
            .to change { Gitlab::Redis::SharedState.with { |redis| redis.get(cache_key) } }
            .from(approval.approved_sha).to(nil)
        end
      end

      it 'tracks merge request unapprove action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_unapprove_mr_action).with(user: user)

        execute!
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestApprovalStateUpdated' do
        let(:action) { execute! }
      end
    end

    context 'with a user who has not approved' do
      it 'does not create an unapproval note and triggers web hook' do
        expect(service).not_to receive(:execute_hooks)
        expect(SystemNoteService).not_to receive(:unapprove_mr)

        execute!
      end

      it 'does not track merge request unapprove action' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_unapprove_mr_action).with(user: user)

        execute!
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { execute! }
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestApprovalStateUpdated' do
        let(:action) { execute! }
      end
    end
  end
end
