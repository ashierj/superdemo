# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::SummarizeNewMergeRequest, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let(:source_project) { project }
  let(:source_branch) { 'feature' }
  let(:target_branch) { 'master' }

  describe '#to_prompt' do
    let(:params) do
      {
        source_project_id: source_project.id,
        source_branch: source_branch,
        target_branch: target_branch
      }
    end

    subject(:template) { described_class.new(user, project, params) }

    shared_examples_for 'prompt without errors' do
      it "returns a prompt with diff" do
        expect(template.to_prompt)
          .to include("+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end")
      end
    end

    it_behaves_like "prompt without errors"

    it 'is under the character limit' do
      expect(template.to_prompt.size).to be <= described_class::CHARACTER_LIMIT
    end

    context 'when user cannot create merge request from source_project_id' do
      let_it_be(:source_project) { create(:project) }

      it_behaves_like "prompt without errors"
    end

    context 'when no source_project_id is specified' do
      let(:params) do
        {
          source_project_id: nil,
          source_branch: source_branch,
          target_branch: target_branch
        }
      end

      it_behaves_like "prompt without errors"
    end

    context "when there is a diff with an edge case" do
      let(:good_diff) { { diff: "@@ -0,0 +1 @@hellothere\n+🌚\n" } }
      let(:compare) { instance_double(Compare) }

      before do
        allow(CompareService).to receive_message_chain(:new, :execute).and_return(compare)
      end

      context 'when a diff is not encoded with UTF-8' do
        let(:other_diff) do
          { diff: "@@ -1 +1 @@\n-This should not be in the prompt\n+#{(0..255).map(&:chr).join}\n" }
        end

        let(:diff_files) { Gitlab::Git::DiffCollection.new([good_diff, other_diff]) }

        it 'does not raise any error and not contain the non-UTF diff' do
          allow(compare).to receive(:raw_diffs).and_return(diff_files)

          expect { template.to_prompt }.not_to raise_error

          expect(template.to_prompt).to include("hellothere")
          expect(template.to_prompt).not_to include("This should not be in the prompt")
        end
      end

      context 'when a diff contains the binary notice' do
        let(:binary_message) { Gitlab::Git::Diff.binary_message('a', 'b') }
        let(:other_diff) { { diff: binary_message } }
        let(:diff_files) { Gitlab::Git::DiffCollection.new([good_diff, other_diff]) }

        it 'does not contain the binary diff' do
          allow(compare).to receive(:raw_diffs).and_return(diff_files)

          expect(template.to_prompt).to include("hellothere")
          expect(template.to_prompt).not_to include(binary_message)
        end
      end

      context 'when extracted diff is blank' do
        before do
          allow(template).to receive(:extracted_diff).and_return([])
        end

        it 'returns nil' do
          expect(template.to_prompt).to be_nil
        end
      end
    end
  end
end
