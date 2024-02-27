# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Duo::Chat::Request, :saas, feature_category: :duo_chat do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project, iid: 1) }
  let_it_be(:epic) { create(:epic, group: subgroup, iid: 2) }
  let(:completions) { instance_double(::Gitlab::Duo::Chat::Completions) }
  let(:query) { 'What is this issue about?' }
  let(:resource) { described_class::Resource.new(type: 'issue', namespace: project.path, iid: 1, ref: '0') }
  let(:datarow) { ::Gitlab::Duo::Chat::DatasetReader::DataRow.new(ref: 'ref', query: query, resource: resource) }
  let(:response_body) { 'response' }

  let(:response) { double }

  subject(:request) do
    described_class.new({ user_id: current_user.id, root_group_path: group.full_path }).completion(datarow)
  end

  before do
    allow(completions).to receive(:execute).and_return(response)
    allow(response).to receive(:response_body).and_return(response_body)
  end

  context 'when question is about issue' do
    let(:resource_record) { issue }

    it 'finds issue' do
      expect(::Gitlab::Duo::Chat::Completions).to receive(:new).with(current_user,
        resource: resource_record).and_return(completions)
      expect(request).to include(ref: 'ref', query: query, response: response_body)
    end

    context 'when question needs formatting' do
      let(:query) { 'Please summarize the current status of the issue %{url}.' }

      it 'formats question with url' do
        url = ::Gitlab::UrlBuilder.build(issue, only_path: false)

        expect(::Gitlab::Duo::Chat::Completions).to receive(:new).with(current_user,
          resource: resource_record).and_return(completions)
        expect(request).to include(query: "Please summarize the current status of the issue #{url}.")
      end
    end
  end

  context 'when question is about epic' do
    let(:resource_record) { epic }
    let(:resource) { described_class::Resource.new(type: 'epic', namespace: subgroup.path, iid: 2, ref: '0') }

    it 'finds epic' do
      expect(::Gitlab::Duo::Chat::Completions).to receive(:new).with(current_user,
        resource: resource_record).and_return(completions)
      expect(request).to include(ref: 'ref', query: query, response: response_body)
    end
  end
end
