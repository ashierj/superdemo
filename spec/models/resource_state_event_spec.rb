# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceStateEvent, feature_category: :team_planning, type: :model do
  subject { build(:resource_state_event, issue: issue) }

  let(:issue) { create(:issue) }
  let(:merge_request) { create(:merge_request) }

  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a resource event for merge requests'
  it_behaves_like 'a note for work item resource event'

  describe 'validations' do
    describe 'Issuable validation' do
      it 'is valid if an issue is set' do
        subject.attributes = { issue: build_stubbed(:issue), merge_request: nil }

        expect(subject).to be_valid
      end

      it 'is valid if a merge request is set' do
        subject.attributes = { issue: nil, merge_request: build_stubbed(:merge_request) }

        expect(subject).to be_valid
      end

      it 'is invalid if both issue and merge request are set' do
        subject.attributes = { issue: build_stubbed(:issue), merge_request: build_stubbed(:merge_request) }

        expect(subject).not_to be_valid
      end

      it 'is invalid if there is no issuable set' do
        subject.attributes = { issue: nil, merge_request: nil }

        expect(subject).not_to be_valid
      end
    end
  end

  context 'callbacks' do
    describe '#issue_usage_metrics' do
      describe 'when an issue is closed' do
        subject(:close_issue) do
          create(
            described_class.name.underscore.to_sym,
            issue: issue,
            state: described_class.states[:closed]
          )
        end

        it 'tracks closed issues' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_closed_action)

          close_issue
        end

        it_behaves_like 'issue_edit snowplow tracking' do
          let(:property) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CLOSED }
          let(:project) { issue.project }
          let(:user) { issue.author }
          subject(:service_action) { close_issue }
        end
      end

      describe 'when an issue is reopened' do
        subject(:reopen_issue) do
          create(
            described_class.name.underscore.to_sym,
            issue: issue,
            state: described_class.states[:reopened]
          )
        end

        it 'tracks reopened issues' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_reopened_action)

          reopen_issue
        end

        it_behaves_like 'issue_edit snowplow tracking' do
          let(:property) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_REOPENED }
          let(:project) { issue.project }
          let(:user) { issue.author }
          subject(:service_action) { reopen_issue }
        end
      end

      it 'does not track merge requests' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_closed_action)

        create(described_class.name.underscore.to_sym, merge_request: merge_request, state: described_class.states[:closed])
      end
    end
  end
end
