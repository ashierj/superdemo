# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::SyncAsWorkItem, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:params) { { title: 'foo', confidential: true, start_date: 1.day.ago, due_date: 5.days.from_now } }

  before_all do
    group.add_developer(user)
  end

  describe '#create_work_item_for!' do
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
          create_work_item_for!(epic)
        end
      end
    end

    subject(:service) { epics_create_service.new(group: group, current_user: user, params: params) }

    it 'defines allowed params' do
      expect(described_class::ALLOWED_PARAMS).to contain_exactly(
        :title, :description, :confidential, :author, :created_at, :updated_at, :updated_by_id,
        :last_edited_by_id, :last_edited_at, :closed_by_id, :closed_at, :state_id, :external_key
      )
    end

    it 'calls WorkItems::CreateService with allowed params' do
      expect(::WorkItems::CreateService).to receive(:new)
        .with(
          container: group,
          current_user: user,
          widget_params: {},
          params: {
            iid: be_a_kind_of(Numeric),
            created_at: be_a_kind_of(Time),
            title: 'foo',
            title_html: 'foo',
            confidential: true,
            work_item_type: WorkItems::Type.default_by_type(:epic),
            extra_params: { synced_work_item: true }
          }
        ).and_call_original

      expect(service.execute).to eq true
    end
  end

  describe '#update_work_item_for!' do
    let_it_be(:work_item) { create(:work_item, namespace: group) }
    let_it_be(:epic) { create(:epic, title: params[:title], issue_id: work_item.id, group: group) }

    let(:epics_update_service) do
      Class.new do
        attr_accessor :group, :current_user, :params

        include Epics::SyncAsWorkItem

        def initialize(group: nil, current_user: nil, params: {})
          @group = group
          @current_user = current_user
          @params = params
        end

        def execute(epic)
          update_work_item_for!(epic)
        end
      end
    end

    subject(:service) { epics_update_service.new(group: group, current_user: user, params: params) }

    it 'calls WorkItems::UpdateService with allowed params' do
      expect_next_instance_of(::WorkItems::UpdateService, container: group,
        current_user: user,
        widget_params: {},
        params: {
          title: 'foo',
          title_html: epic.title_html,
          updated_by: epic.updated_by,
          updated_at: epic.updated_at,
          confidential: true,
          extra_params: { synced_work_item: true }
        }
      ) do |instance|
        expect(instance).to receive(:execute).with(epic.work_item).and_return({ status: :success })
      end

      expect(service.execute(epic)).to eq true
    end

    context 'when epic description has been edited' do
      let_it_be(:params) { { description: 'new description' } }

      before do
        epic.assign_attributes(last_edited_by: user, last_edited_at: Time.current)
        allow(epic).to receive(:edited?).and_return(true)
      end

      it 'WorkItems::UpdateService includes edited params' do
        expect_next_instance_of(::WorkItems::UpdateService, container: group,
          current_user: user,
          widget_params: {},
          params: {
            description: 'new description',
            description_html: epic.description_html,
            last_edited_by: epic.last_edited_by,
            last_edited_at: epic.last_edited_at,
            updated_by: epic.updated_by,
            updated_at: epic.updated_at,
            extra_params: { synced_work_item: true }
          }
        ) do |instance|
          expect(instance).to receive(:execute).with(epic.work_item).and_return({ status: :success })
        end

        expect(service.execute(epic)).to eq true
      end
    end
  end
end
