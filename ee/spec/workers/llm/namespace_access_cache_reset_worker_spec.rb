# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::NamespaceAccessCacheResetWorker, feature_category: :ai_abstraction_layer do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:sub_group) { create(:group, parent: group) }

  let_it_be(:group_member) { create(:group_member, group: group, user: create(:user)) }
  let_it_be(:sub_group_member) { create(:group_member, group: sub_group, user: create(:user)) }
  let_it_be(:project_member) { create(:project_member, project: project, user: create(:user)) }

  let(:data) { { group_id: group.id } }
  let(:subscription_started_event) { NamespaceSettings::AiRelatedSettingsChangedEvent.new(data: data) }

  it_behaves_like 'subscribes to event' do
    let(:event) { subscription_started_event }
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  context 'when group can not be found' do
    let(:data) { { group_id: non_existing_record_id } }

    it 'does not call Rails.cache' do
      expect(Rails.cache).not_to receive(:delete_multi)

      consume_event(subscriber: described_class, event: subscription_started_event)
    end
  end

  context 'when cache is already set', :use_clean_rails_redis_caching do
    before do
      group_member.user.any_group_with_ai_available?
      sub_group_member.user.any_group_with_ai_available?
      project_member.user.any_group_with_ai_available?
    end

    it 'deletes cache from all users of the group' do
      expect(Rails.cache.fetch(['users', group_member.user.id, 'group_with_ai_enabled'])).to eq(false)
      expect(Rails.cache.fetch(['users', sub_group_member.user.id, 'group_with_ai_enabled'])).to eq(false)
      expect(Rails.cache.fetch(['users', project_member.user.id, 'group_with_ai_enabled'])).to eq(false)

      consume_event(subscriber: described_class, event: subscription_started_event)

      expect(Rails.cache.fetch(['users', group_member.user.id, 'group_with_ai_enabled'])).to be_nil
      expect(Rails.cache.fetch(['users', sub_group_member.user.id, 'group_with_ai_enabled'])).to be_nil
      expect(Rails.cache.fetch(['users', project_member.user.id, 'group_with_ai_enabled'])).to be_nil
    end
  end

  context 'when user is member multiple times', :use_clean_rails_redis_caching do
    let_it_be(:project_member2) { create(:project_member, project: project, user: sub_group_member.user) }

    it 'calls cache deletion only once per user' do
      expect(Rails.cache).to receive(:delete_multi)
        .with(match_array([
          ['users', group_member.user.id, 'group_with_ai_enabled'],
          ['users', sub_group_member.user.id, 'group_with_ai_enabled'],
          ['users', project_member.user.id, 'group_with_ai_enabled']
        ]))

      consume_event(subscriber: described_class, event: subscription_started_event)
    end
  end
end
