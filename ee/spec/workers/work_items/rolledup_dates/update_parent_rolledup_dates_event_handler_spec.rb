# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::RolledupDates::UpdateParentRolledupDatesEventHandler, feature_category: :portfolio_management do
  describe '.can_handle_update?', :aggregate_failures do
    it 'returns false if no expected widget or attribute changed' do
      event = ::WorkItems::WorkItemCreatedEvent.new(data: { id: 1, namespace_id: 2 })
      expect(described_class.can_handle_update?(event)).to eq(false)
    end

    it 'returns true when expected attribute changed' do
      described_class::UPDATE_TRIGGER_ATTRIBUTES.each do |attribute|
        event = ::WorkItems::WorkItemCreatedEvent.new(data: {
          id: 1,
          namespace_id: 2,
          updated_attributes: [attribute]
        })

        expect(described_class.can_handle_update?(event)).to eq(true)
      end
    end

    it 'returns true when expected widget changed' do
      described_class::UPDATE_TRIGGER_WIDGETS.each do |widget|
        event = ::WorkItems::WorkItemCreatedEvent.new(data: {
          id: 1,
          namespace_id: 2,
          updated_widgets: [widget]
        })

        expect(described_class.can_handle_update?(event)).to eq(true)
      end
    end
  end

  describe "handle_event" do
    context "when work item has a parent" do
      it "updates the work_item hierarchy" do
        parent = instance_double(::WorkItem)

        expect(::WorkItem)
          .to receive(:find)
            .with(1)
            .and_return(instance_double(::WorkItem, work_item_parent: parent))

        expect_next_instance_of(::WorkItems::Widgets::RolledupDatesService::HierarchyUpdateService, parent) do |service|
          expect(service).to receive(:execute)
        end

        event = ::WorkItems::WorkItemCreatedEvent.new(data: { id: 1, namespace_id: 2 })

        handler = described_class.new
        handler.handle_event(event)
      end
    end

    context "when work item does not have a parent" do
      it "updates the work_item hierarchy" do
        expect(::WorkItem)
          .to receive(:find)
            .with(1)
            .and_return(instance_double(::WorkItem, work_item_parent: nil))

        expect(::WorkItems::Widgets::RolledupDatesService::HierarchyUpdateService)
          .not_to receive(:new)

        event = ::WorkItems::WorkItemCreatedEvent.new(data: { id: 1, namespace_id: 2 })

        handler = described_class.new
        handler.handle_event(event)
      end
    end
  end
end
