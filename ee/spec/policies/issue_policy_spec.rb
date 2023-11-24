# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePolicy, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:authorizer) { instance_double(::Gitlab::Llm::FeatureAuthorizer) }

  subject { described_class.new(user, issue) }

  before do
    allow(::Gitlab::Llm::FeatureAuthorizer).to receive(:new).and_return(authorizer)
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
end
