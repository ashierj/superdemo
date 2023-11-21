# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_tier_badge.html.haml', :saas, feature_category: :groups_and_projects do
  let(:parent) { build(:group, :private, id: non_existing_record_id) }
  let(:subgroup) { build_stubbed(:group, :private, parent: parent) }
  let(:selector) { '.js-tier-badge-trigger' }

  before do
    stub_experiments(tier_badge: tier_badge)
    allow(view).to receive(:show_tier_badge_for_new_trial?).and_return(true)
  end

  context 'when control' do
    let(:tier_badge) { :control }

    it 'does not render anything' do
      render 'shared/tier_badge', source: parent, namespace_to_track: parent

      expect(rendered).not_to have_selector(selector)
    end
  end

  context 'when candidate' do
    let(:tier_badge) { :candidate }

    context 'when free parent' do
      it 'renders tier_badge' do
        render 'shared/tier_badge', source: parent, namespace_to_track: parent

        expect(rendered).to have_selector(selector)
      end
    end

    context 'when free subgroup' do
      it 'renders tier_badge' do
        render 'shared/tier_badge', source: subgroup, namespace_to_track: subgroup

        expect(rendered).to have_selector(selector)
      end
    end

    context 'when free parent with expired trial' do
      it 'does not render anything' do
        build(:gitlab_subscription, :expired_trial, namespace: parent)

        render 'shared/tier_badge', source: parent, namespace_to_track: parent

        expect(rendered).not_to have_selector(selector)
      end
    end

    context 'when the parent namespace is not private' do
      let(:parent) { build(:group, :public, id: non_existing_record_id) }

      it 'does not render anything' do
        render 'shared/tier_badge', source: parent, namespace_to_track: parent

        expect(rendered).not_to have_selector(selector)
      end
    end
  end
end
