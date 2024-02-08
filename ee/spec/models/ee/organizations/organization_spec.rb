# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Organization, feature_category: :cell do
  describe 'associations' do
    it { is_expected.to have_many(:sbom_occurrences).through(:projects).class_name('Sbom::Occurrence') }
  end
end
