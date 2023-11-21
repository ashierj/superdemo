# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Llm::SummarizeMergeRequestWorker, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let(:params) do
    [user.id,
      { merge_request_id: merge_request.id,
        type: ::MergeRequests::Llm::SummarizeMergeRequestWorker::SUMMARIZE_QUICK_ACTION }]
  end

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let_it_be(:message) { 'this is a message from the llm' }

  subject(:worker) { described_class.new }

  it "returns nil" do
    expect(worker.perform(*params)).to be_nil
  end
end
