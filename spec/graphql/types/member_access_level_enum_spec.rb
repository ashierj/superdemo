# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MemberAccessLevelEnum, feature_category: :subgroups do
  specify { expect(described_class.graphql_name).to eq('MemberAccessLevel') }

  it 'exposes all the existing access levels' do
    expect(described_class.values.keys).to include(*%w[GUEST REPORTER DEVELOPER MAINTAINER OWNER])
  end
end
