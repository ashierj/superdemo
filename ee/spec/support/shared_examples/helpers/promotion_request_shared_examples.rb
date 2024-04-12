# frozen_string_literal: true

RSpec.shared_examples 'adding promotion_request in app data' do
  context 'when pending_members is nil' do
    let!(:pending_members) { nil }

    it 'returns `promotion_request` property with []' do
      expect(helper_app_data[:promotion_request]).to eq []
    end
  end

  context 'when pending_members is not nil' do
    let!(:pending_members) do
      create_list(:member_approval, 2, type, member_namespace: member_namespace)
    end

    it 'returns valid `promotion_request`' do
      expect(helper_app_data[:promotion_request].keys).to match_array([:data, :pagination])
      expect(helper_app_data[:promotion_request][:data].size).to eq(2)
      expect(helper_app_data[:promotion_request][:data].first.keys).to match_array [:id, :created_at,
        :updated_at, :requested_by, :reviewed_by, :new_access_level, :old_access_level, :source, :user]
    end
  end
end
