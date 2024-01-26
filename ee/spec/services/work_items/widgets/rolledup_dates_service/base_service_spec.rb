# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::Widgets::RolledupDatesService::BaseService, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user).tap { |user| group.add_developer(user) } }
  let_it_be_with_reload(:work_item) { create(:work_item, :epic, namespace: group) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::RolledupDates) } }
  let(:start_date) { 1.day.ago.to_date }
  let(:due_date) { 1.day.from_now.to_date }
  let(:params) { { start_date: start_date, due_date: due_date } }

  let(:service_class) do
    Class.new(described_class) do
      def execute(params:)
        handle_rolledup_dates_change(params)
      end
    end
  end

  before do
    allow(::WorkItems::Widgets::RolledupDatesService::AttributesBuilder)
      .to receive(:build)
      .and_return(
        start_date: start_date,
        start_date_is_fixed: true,
        due_date: due_date,
        due_date_is_fixed: true)
  end

  subject(:service) { service_class.new(widget: widget, current_user: user) }

  context "when dates source does not exist" do
    it "creates the work_item dates_souce and populates it" do
      expect { service.execute(params: params) }
        .to change { WorkItems::DatesSource.count }

      dates_source = work_item.dates_source
      expect(dates_source.start_date).to eq(start_date)
      expect(dates_source.start_date_is_fixed).to eq(true)
      expect(dates_source.due_date).to eq(due_date)
      expect(dates_source.due_date_is_fixed).to eq(true)
    end
  end

  context "when dates source already exists" do
    before do
      create(
        :work_items_dates_source,
        work_item: work_item,
        start_date: 2.days.ago,
        due_date: 2.days.from_now)
    end

    it "updates the work_item dates_souce and populates it" do
      service.execute(params: params)

      dates_source = work_item.dates_source
      expect(dates_source.start_date).to eq(start_date)
      expect(dates_source.start_date_is_fixed).to eq(true)
      expect(dates_source.due_date).to eq(due_date)
      expect(dates_source.due_date_is_fixed).to eq(true)
    end
  end
end
