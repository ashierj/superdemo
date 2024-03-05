# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Utils::Authorizer, feature_category: :ai_abstraction_layer do
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) {  create(:project, group: group) }
  let_it_be_with_reload(:resource) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }
  let(:container) { project }

  describe '.container' do
    subject(:response) { described_class.container(container: container, user: user) }

    before do
      allow(user).to receive(:can?).with(:access_duo_features, container).and_return(allowed)
    end

    context 'when user is allowed' do
      let(:allowed) { true }

      it "returns an authorized response" do
        expect(response.allowed?).to be(true)
      end
    end

    context 'when user is not allowed' do
      let(:allowed) { false }

      it "returns an error not found response when the user isn't a member of the container" do
        expect(response.allowed?).to be(false)
        expect(response.message).to eq("I am sorry, I am unable to find what you are looking for.")
      end

      it "returns a not allowed response when the user is a member of the container" do
        container.add_guest(user)

        expect(response.allowed?).to be(false)
        expect(response.message).to eq("This feature is only allowed in groups or projects that enable this feature.")
      end
    end
  end

  describe '.resource' do
    subject(:response) { described_class.resource(resource: resource, user: user) }

    context 'when resource is nil' do
      let(:resource) { nil }

      it 'returns false' do
        expect(response.allowed?).to be(false)
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it 'returns false' do
        expect(response.allowed?).to be(false)
      end
    end

    context 'when resource parent is not authorized' do
      it 'returns false' do
        expect(response.allowed?).to be(false)
      end
    end

    context 'when resource container is authorized' do
      it 'calls user.can? with the appropriate arguments' do
        expect(user).to receive(:can?).with('read_issue', resource)

        response
      end
    end

    context 'when resource is current user' do
      let(:resource) { user }

      it 'returns true' do
        expect(response.allowed?).to be(true)
      end
    end

    context 'when resource is different user' do
      let(:resource) { build(:user) }

      it 'returns false' do
        expect(response.allowed?).to be(false)
      end
    end
  end

  describe '.user' do
    subject(:response) { described_class.user(user: user) }

    it 'returns true' do
      expect(response.allowed?).to be(true)
    end
  end
end
