# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::RolledupDates::UpdateParentRolledupDatesEventHandler, feature_category: :portfolio_management do
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
