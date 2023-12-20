# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::GroupsHelper, feature_category: :activation do
  describe '#active_tab_classes' do
    let(:user_detail) { build_stubbed(:user_detail, registration_objective: registration_objective) }
    let(:user) { build_stubbed(:user, user_detail: user_detail) }
    let(:registration_objective) { 'move_repository' }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when default_to_import_tab is control' do
      before do
        stub_experiments(default_to_import_tab: :control)
      end

      it 'returns active create tab' do
        expect(helper.active_tab_classes).to eq({ create_tab: 'active', import_tab: '' })
      end
    end

    context 'when default_to_import_tab is candidate' do
      before do
        stub_experiments(default_to_import_tab: :candidate)
      end

      it 'returns active import tab' do
        expect(helper.active_tab_classes).to eq({ create_tab: '', import_tab: 'active' })
      end

      context 'when code_storage registration objective' do
        let(:registration_objective) { 'code_storage' }

        it 'returns active create tab' do
          expect(helper.active_tab_classes).to eq({ create_tab: 'active', import_tab: '' })
        end
      end
    end
  end
end
