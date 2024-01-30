# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::MergeRequestsService, feature_category: :code_review_workflow do
  include Gitlab::Routing

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:author) { create(:user) }

  let(:noteable) { create(:merge_request, source_project: project, target_project: project) }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '.merge_when_checks_pass' do
    let(:pipeline) { build(:ci_pipeline) }

    subject { service.merge_when_checks_pass(pipeline.sha) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when checks pass' system note" do
      expect(subject.note).to(
        match("enabled an automatic merge when all merge checks for #{pipeline.sha} pass")
      )
    end
  end

  describe '#approvals_reset' do
    let(:cause) { :new_push }
    let_it_be(:approvers) { create_list(:user, 3) }

    subject(:approvals_reset_note) do
      described_class
        .new(noteable: noteable, project: project, author: author)
        .approvals_reset(cause, approvers)
    end

    it_behaves_like 'a system note' do
      let(:action) { 'approvals_reset' }
    end

    it 'sets the note text' do
      expect(approvals_reset_note.note)
        .to eq("reset approvals from #{approvers.map(&:to_reference).to_sentence} by pushing to the branch")
    end

    context 'when cause is not new_push' do
      let(:cause) { :something_else }

      it 'returns nil' do
        expect(approvals_reset_note).to be_nil
      end
    end

    context 'when there are no approvers' do
      let_it_be(:approvers) { [] }

      it 'returns nil' do
        expect(approvals_reset_note).to be_nil
      end
    end
  end
end
