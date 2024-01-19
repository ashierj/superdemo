# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::SyncAsWorkItem, feature_category: :portfolio_management do
  describe '#create_work_item_for' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:params) { { title: 'foo', confidential: true, start_date: 1.day.ago, due_date: 5.days.from_now } }

    let(:epics_create_service) do
      Class.new do
        attr_accessor :group, :current_user, :params

        include Epics::SyncAsWorkItem

        def initialize(group: nil, current_user: nil, params: {})
          @group = group
          @current_user = current_user
          @params = params
        end

        def execute
          epic = group.epics.new(params.merge({ group: group, author: current_user }))
          epic.save!
          create_work_item_for(epic)
        end
      end
    end

    subject(:service) { epics_create_service.new(group: group, current_user: user, params: params) }

    it 'defines allowed params' do
      expect(described_class::ALLOWED_PARAMS).to contain_exactly(
        :title, :description, :confidential, :author, :created_at, :updated_at, :updated_by_id,
        :last_edited_by_id, :last_edited_at, :closed_by_id, :closed_at, :state_id
      )
    end

    it 'calls WorkItems::CreateService with allowed params' do
      allow_next_instance_of(::WorkItems::CreateService) do |instance|
        allow(instance).to receive(:execute_without_rate_limiting).and_return({ status: :success })
      end

      expect(::WorkItems::CreateService).to receive(:new)
        .with(
          container: group,
          current_user: user,
          params: {
            iid: be_a_kind_of(Numeric),
            created_at: be_a_kind_of(Time),
            title: 'foo',
            confidential: true,
            work_item_type: WorkItems::Type.default_by_type(:epic),
            extra_params: { synced_work_item: true }
          },
          widget_params: {}
        )

      service.execute
    end
  end
end
