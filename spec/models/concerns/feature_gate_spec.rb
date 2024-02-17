# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureGate do
  describe '.actor_from_id' do
    using RSpec::Parameterized::TableSyntax

    subject(:actor_from_id) { model_class.actor_from_id(model_id) }

    where(:model_class, :model_id, :expected) do
      Project | 1 | 'Project:1'
      Group   | 2 | 'Group:2'
      User    | 3 | 'User:3'
    end

    with_them do
      it 'returns an object that has the correct flipper_id' do
        expect(actor_from_id).to have_attributes(flipper_id: expected)
      end
    end
  end

  describe 'User' do
    describe '#flipper_id' do
      context 'when user is not persisted' do
        let(:user) { build(:user) }

        it { expect(user.flipper_id).to be_nil }
      end

      context 'when user is persisted' do
        let(:user) { create(:user) }

        it { expect(user.flipper_id).to eq "User:#{user.id}" }
      end
    end
  end
end
