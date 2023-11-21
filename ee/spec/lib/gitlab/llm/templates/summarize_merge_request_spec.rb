# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::SummarizeMergeRequest, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }

  let(:merge_request) do
    create(
      :merge_request,
      source_branch: source_branch,
      target_branch: 'master',
      source_project: project,
      target_project: project
    )
  end

  let(:mr_diff) { merge_request.merge_request_diff }
  let(:source_branch) { 'feature' }

  subject { described_class.new(merge_request, mr_diff) }

  describe '#to_prompt' do
    it 'includes raw diff' do
      expect(subject.to_prompt)
        .to include("+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end")
    end

    context 'when a diff is not encoded with UTF-8' do
      let(:source_branch) { 'signed-commits' }

      it 'does not raise any error' do
        mr_diff.raw_diffs.to_a[0].diff = "@@ -0,0 +1 @@hellothere\n+🌚\n"

        non_utf_diff = "@@ -1 +1 @@\n-This should not be in the prompt\n+#{(0..255).map(&:chr).join}\n"
        mr_diff.raw_diffs.to_a[1].diff = non_utf_diff

        expect { subject.to_prompt }.not_to raise_error
        expect(subject.to_prompt).to include("hellothere")
        expect(subject.to_prompt).not_to include("This should not be in the prompt")
      end
    end
  end
end
