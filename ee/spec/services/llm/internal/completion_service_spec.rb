# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::Internal::CompletionService, :saas, feature_category: :ai_abstraction_layer do
  include FakeBlobHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:resource) { create(:issue, project: project) }
  let(:options) { { 'key' => 'value' } }
  let(:ai_action_name) { :summarize_comments }
  let(:referer_url) { nil }
  let(:extra_resource) { {} }
  let(:completion) { instance_double(Gitlab::Llm::Completions::SummarizeAllOpenNotes) }

  let(:prompt_message) do
    build(:ai_message, user: user, resource: resource, ai_action: ai_action_name, request_id: 'uuid')
  end

  let(:params) do
    options.merge(referer_url: referer_url)
  end

  subject(:service) { described_class.new(prompt_message, params) }

  include_context 'with ai features enabled for group'

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'performs successfully' do
      it 'calls Gitlab::Llm::CompletionsFactory', :aggregate_failures do
        completion = instance_double(Gitlab::Llm::Completions::SummarizeAllOpenNotes)
        extra_resource_finder = instance_double(::Llm::ExtraResourceFinder)

        expect(::Llm::ExtraResourceFinder).to receive(:new).with(user, referer_url).and_return(extra_resource_finder)
        expect(extra_resource_finder).to receive(:execute).and_return(extra_resource)

        expect(Gitlab::Llm::CompletionsFactory)
          .to receive(:completion!)
          .with(an_object_having_attributes(
            user: user,
            resource: resource,
            request_id: 'uuid',
            ai_action: ai_action_name
          ),
            options.symbolize_keys.merge(extra_resource: extra_resource))
          .and_return(completion)

        expect(completion).to receive(:execute)

        execute
      end
    end

    context 'with valid parameters' do
      before_all do
        group.add_reporter(user)
      end

      it 'updates duration metric' do
        allow(Gitlab::Llm::CompletionsFactory)
          .to receive(:completion!)
          .and_return(completion)
        allow(completion).to receive(:execute)

        expect(Gitlab::Metrics::Sli::Apdex[:llm_completion])
          .to receive(:increment)
          .with(labels: { feature_category: anything, service_class: an_instance_of(String) }, success: true)

        execute
      end

      context 'when extra resource is found' do
        let(:referer_url) { "foobar" }
        let(:extra_resource) { { blob: fake_blob(path: 'file.md') } }

        it_behaves_like 'performs successfully'
      end

      context 'for an issue' do
        let_it_be(:resource) { create(:issue, project: project) }

        it_behaves_like 'performs successfully'
      end

      context 'for a work item' do
        let_it_be(:resource) { create(:work_item, :task, project: project) }

        it_behaves_like 'performs successfully'
      end

      context 'for a merge request' do
        let_it_be(:resource) { create(:merge_request, source_project: project) }

        it_behaves_like 'performs successfully'
      end

      context 'for an epic' do
        before do
          stub_licensed_features(epics: true)
        end

        let_it_be(:resource) { create(:epic, group: group) }

        it_behaves_like 'performs successfully'
      end

      context 'when resource is nil' do
        let_it_be(:resource) { nil }
        let(:ai_action_name) { :chat }

        it_behaves_like 'performs successfully'
      end
    end

    context 'with service failure' do
      before_all do
        group.add_reporter(user)
      end

      before do
        allow(Gitlab::Llm::CompletionsFactory).to receive(:completion!).and_return(completion)
        allow(completion).to receive(:execute).and_raise(StandardError, 'service failure')
      end

      it 'updates error rate' do
        expect(Gitlab::Metrics::Sli::ErrorRate[:llm_completion])
          .to receive(:increment)
          .with(labels: {
            feature_category: :ai_abstraction_layer,
            service_class: 'Gitlab::Llm::Completions::SummarizeAllOpenNotes'
          }, error: true)

        expect do
          execute
        end.to raise_error(StandardError, 'service failure')
      end
    end

    context 'when user can not read the resource' do
      it 'does not call Gitlab::Llm::CompletionsFactory.completion!' do
        expect(Gitlab::Llm::CompletionsFactory).not_to receive(:completion!)

        execute
      end
    end
  end
end
