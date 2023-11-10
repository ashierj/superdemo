# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Utils::Authorizer, :saas, feature_category: :duo_chat do
  let_it_be(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
  let_it_be_with_reload(:project) {  create(:project, group: group) }
  let_it_be_with_reload(:resource) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }
  let(:container) { project }
  let(:context) do
    Gitlab::Llm::Chain::GitlabContext.new(
      current_user: user,
      container: container,
      resource: resource,
      ai_request: nil
    )
  end

  subject(:authorizer) { described_class }

  before_all do
    group.add_developer(user)
  end

  shared_examples 'user authorization' do
    context 'when user has groups with ai available' do
      include_context 'with ai features enabled for group'
      it 'returns true' do
        expect(authorizer.user(user: user).allowed?).to be(true)
      end
    end

    context 'when user has no groups with ai available' do
      include_context 'with experiment features disabled for group'

      it 'returns true when user has no groups with ai available' do
        expect(authorizer.user(user: user).allowed?).to be(false)
        expect(authorizer.user(user: user).message).to eq('You do not have access to AI features.')
      end
    end
  end

  describe '.context.allowed?' do
    context 'when both resource and container are present' do
      context 'when container is authorized' do
        include_context 'with ai features enabled for group'

        it 'returns true if both resource and container are authorized' do
          expect(authorizer.context(context: context).allowed?).to be(true)
        end

        it 'returns false if resource is not authorized' do
          group.members.first.destroy!

          expect(authorizer.context(context: context).allowed?).to be(false)
          expect(authorizer.context(context: context).message)
            .to include('I am unable to find what you are looking for.')
        end
      end

      context 'when container is not authorized' do
        include_context 'with experiment features disabled for group'

        it 'returns false if container is not authorized' do
          expect(authorizer.context(context: context).allowed?).to be(false)
          expect(authorizer.context(context: context).message)
            .to eq('This feature is only allowed in groups that enable this feature.')
        end
      end
    end

    context 'when only resource is present' do
      let(:context) do
        Gitlab::Llm::Chain::GitlabContext.new(
          current_user: user,
          container: nil,
          resource: resource,
          ai_request: nil
        )
      end

      context 'when resource container is authorized' do
        include_context 'with ai features enabled for group'

        it 'returns true' do
          expect(authorizer.context(context: context).allowed?).to be(true)
        end
      end

      context 'when container is not authorized' do
        include_context 'with experiment features disabled for group'

        it 'returns false' do
          expect(authorizer.context(context: context).allowed?).to be(false)
        end
      end
    end

    context 'when only container is present' do
      let(:context) do
        Gitlab::Llm::Chain::GitlabContext.new(
          current_user: nil,
          container: container,
          resource: nil,
          ai_request: nil
        )
      end

      context 'when container is authorized' do
        include_context 'with ai features enabled for group'

        it 'returns true' do
          expect(authorizer.context(context: context).allowed?).to be(false)
        end
      end

      context 'when container is not authorized' do
        include_context 'with experiment features disabled for group'

        it 'returns false' do
          expect(authorizer.context(context: context).allowed?).to be(false)
        end
      end
    end

    context 'when neither resource nor container is present' do
      let(:context) do
        Gitlab::Llm::Chain::GitlabContext.new(
          current_user: user,
          container: nil,
          resource: nil,
          ai_request: nil
        )
      end

      context 'when user is authorized' do
        include_context 'with ai features enabled for group'

        it 'returns true' do
          expect(authorizer.context(context: context).allowed?).to be(true)
        end
      end

      context 'when user is not authorized' do
        include_context 'with experiment features disabled for group'

        it 'returns false' do
          expect(authorizer.context(context: context).allowed?).to be(false)
        end
      end
    end
  end

  describe '.container?' do
    it "calls Gitlab::Llm::StageCheck.available? with the appropriate arguments" do
      expect(Gitlab::Llm::StageCheck).to receive(:available?).with(container, :chat)

      authorizer.container(container: context.container, user: user)
    end

    it 'uses resource from argument' do
      new_container = build(:group)
      expect(new_container).to receive(:member?).and_return(true)
      expect(Gitlab::Llm::StageCheck).to receive(:available?).with(new_container, :chat)

      authorizer.container(container: new_container, user: user)
    end
  end

  describe '.resource' do
    context 'when resource is nil' do
      let(:resource) { nil }

      it 'returns false' do
        expect(authorizer.resource(resource: context.resource, user: context.current_user).allowed?)
          .to be(false)
      end
    end

    context 'when resource parent is not authorized' do
      include_context 'with experiment features disabled for group'

      it 'returns false' do
        expect(authorizer.resource(resource: context.resource, user: context.current_user).allowed?)
          .to be(false)
      end
    end

    context 'when resource container is authorized' do
      include_context 'with ai features enabled for group'

      it 'calls user.can? with the appropriate arguments' do
        expect(user).to receive(:can?).with('read_issue', resource)

        authorizer.resource(resource: context.resource, user: context.current_user)
      end

      it 'uses resource from argument' do
        new_resource = build(:epic)

        expect(new_resource).to receive(:resource_parent).and_return(group)
        expect(user).to receive(:can?).with('read_epic', new_resource)

        authorizer.resource(resource: new_resource, user: context.current_user)
      end
    end
  end

  describe '.user' do
    it_behaves_like 'user authorization'
  end
end
