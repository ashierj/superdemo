# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::EnabledNamespace, feature_category: :global_search do
  let_it_be(:namespace) { create(:group) }

  subject { create(:zoekt_enabled_namespace, namespace: namespace) }

  describe 'relations' do
    it { is_expected.to belong_to(:namespace).inverse_of(:zoekt_enabled_namespace) }
    it { is_expected.to have_many(:indices) }
  end

  describe 'validations' do
    it 'only allows root namespaces to be indexed' do
      subgroup = create(:group, parent: namespace)

      expect(described_class.new(namespace: subgroup)).to be_invalid
    end
  end
end
