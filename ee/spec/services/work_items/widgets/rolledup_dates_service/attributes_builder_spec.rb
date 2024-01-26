# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::Widgets::RolledupDatesService::AttributesBuilder, feature_category: :portfolio_management do
  let_it_be_with_reload(:work_item) { create(:work_item, :epic) }

  let(:start_date) { 1.day.ago.to_date }
  let(:due_date) { 1.day.from_now.to_date }
  let(:milestone) { instance_double(::Milestone, id: 1, start_date: start_date - 1.day, due_date: due_date + 1.day) }

  def query_result(values)
    instance_double(WorkItems::DatesSource, {
      due_date: nil,
      due_date_is_fixed: nil,
      due_date_sourcing_milestone_id: nil,
      due_date_sourcing_work_item_id: nil,
      start_date: nil,
      start_date_is_fixed: nil,
      start_date_sourcing_milestone_id: nil,
      start_date_sourcing_work_item_id: nil
    }.merge(values))
  end

  before do
    allow_next_instance_of(WorkItems::Widgets::RolledupDatesFinder) do |finder|
      allow(finder)
        .to receive(:minimum_start_date)
        .and_return([query_result(start_date: milestone.start_date, start_date_sourcing_milestone_id: milestone.id)])

      allow(finder)
        .to receive(:maximum_due_date)
        .and_return([query_result(due_date: milestone.due_date, due_date_sourcing_milestone_id: milestone.id)])
    end
  end

  subject(:builder) { described_class.new(work_item, params) }

  describe "#build" do
    context "when params[:start_date_fixed] and params[:due_date_fixed] is present" do
      let(:params) { { start_date_fixed: start_date, due_date_fixed: due_date } }

      it "creates the work_item dates_souce and populates it" do
        expect(builder.build).to eq(
          due_date: due_date,
          due_date_fixed: due_date,
          due_date_is_fixed: true,
          start_date: start_date,
          start_date_fixed: start_date,
          start_date_is_fixed: true
        )
      end
    end

    context "when only params[:start_date_fixed] is present" do
      let(:params) { { start_date_fixed: start_date } }

      it "creates the work_item dates_souce and populates it" do
        expect(builder.build).to eq(
          due_date: milestone.due_date,
          due_date_is_fixed: false,
          due_date_sourcing_milestone_id: milestone.id,
          due_date_sourcing_work_item_id: nil,
          start_date: start_date,
          start_date_fixed: start_date,
          start_date_is_fixed: true
        )
      end
    end

    context "when only params[:start_date_fixed] is not present and params[:start_date_is_fixed] is true" do
      let(:params) { { start_date_is_fixed: true } }

      it "creates the work_item dates_souce and populates it" do
        expect(builder.build).to eq(
          due_date: milestone.due_date,
          due_date_is_fixed: false,
          due_date_sourcing_milestone_id: milestone.id,
          due_date_sourcing_work_item_id: nil,
          start_date_is_fixed: true
        )
      end
    end

    context "when only params[:due_date_fixed] is present" do
      let(:params) { { due_date_fixed: due_date } }

      it "creates the work_item dates_souce and populates it" do
        expect(builder.build).to eq(
          due_date: due_date,
          due_date_fixed: due_date,
          due_date_is_fixed: true,
          start_date: milestone.start_date,
          start_date_is_fixed: false,
          start_date_sourcing_milestone_id: milestone.id,
          start_date_sourcing_work_item_id: nil
        )
      end
    end

    context "when only params[:due_date_fixed] is not present and params[:due_date_is_fixed] is true" do
      let(:params) { { due_date_is_fixed: true } }

      it "creates the work_item dates_souce and populates it" do
        expect(builder.build).to eq(
          due_date_is_fixed: true,
          start_date: milestone.start_date,
          start_date_is_fixed: false,
          start_date_sourcing_milestone_id: milestone.id,
          start_date_sourcing_work_item_id: nil
        )
      end
    end

    context "when all params are empty" do
      let(:params) { {} }

      it "creates the work_item dates_souce and populates it" do
        expect(builder.build).to eq(
          due_date: milestone.due_date,
          due_date_is_fixed: false,
          due_date_sourcing_milestone_id: milestone.id,
          due_date_sourcing_work_item_id: nil,
          start_date: milestone.start_date,
          start_date_is_fixed: false,
          start_date_sourcing_milestone_id: milestone.id,
          start_date_sourcing_work_item_id: nil
        )
      end
    end
  end
end
