# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::RolledupDatesInputType, feature_category: :team_planning do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetRolledupDatesInput') }

  it do
    expect(described_class.arguments.keys).to contain_exactly(
      "dueDateFixed",
      "dueDateIsFixed",
      "startDateFixed",
      "startDateIsFixed"
    )
  end
end
