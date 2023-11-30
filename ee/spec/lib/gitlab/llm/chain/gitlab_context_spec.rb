# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::GitlabContext, :saas, feature_category: :duo_chat do
  let_it_be(:user) { create(:user) }
  let(:resource) { nil }
  let(:ai_request) { instance_double(Gitlab::Llm::Chain::Requests::Anthropic) }

  subject(:context) do
    described_class.new(current_user: user, container: nil, resource: resource, ai_request: ai_request)
  end

  describe '#resource_json' do
    let(:content_limit) { 500 }

    context 'with a serializable resource' do
      let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
      let_it_be(:project) { create(:project, group: group) }
      let(:resource) { create(:issue, project: project) }
      let(:resource_json) do
        Ai::AiResource::Issue.new(resource).serialize_for_ai(user: user, content_limit: content_limit).to_json
      end

      before_all do
        group.add_reporter(user)
      end

      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        stub_licensed_features(experimental_features: true, ai_features: true)
        group.namespace_settings.update!(experiment_features_enabled: true)
      end

      it 'returns the AI serialization of the resource' do
        expect(context.resource_json(content_limit: content_limit)).to eq(resource_json)
      end
    end

    context 'with an unauthorized resource' do
      let(:resource) { create(:issue) }

      it 'returns an empty string' do
        expect(context.resource_json(content_limit: content_limit)).to eq('')
      end
    end

    context 'with a non-serializable resource' do
      it 'raises an ArgumentError' do
        expect { context.resource_json(content_limit: content_limit) }.to raise_error(ArgumentError)
      end
    end
  end
end
