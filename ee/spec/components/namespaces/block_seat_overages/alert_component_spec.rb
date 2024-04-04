# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/FactoryBot/AvoidCreate -- will not work with build_stubbed
RSpec.describe Namespaces::BlockSeatOverages::AlertComponent, type: :component, feature_category: :consumables_cost_management do
  include ReactiveCachingHelpers

  let_it_be_with_refind(:group) { create(:group, name: "My Group") }
  let_it_be(:current_user) { create(:user) }

  describe '#title' do
    it 'returns the title including the group name' do
      expect(component.title).to include('My Group')
    end

    it 'uses the root group name when given a subgroup' do
      subgroup = create(:group, parent: group, name: "My Subgroup")

      expect(component(subgroup).title).to include('My Group')
    end
  end

  describe '#render?' do
    before do
      synchronous_reactive_cache(group)
    end

    context 'in a self-managed environment' do
      it 'returns false' do
        expect(component.render?).to eq(false)
      end
    end

    context 'in a saas environment', :saas do
      let_it_be(:subscription) { create(:gitlab_subscription, :premium, namespace: group, seats: 1) }

      before_all do
        group.add_developer(create(:user))
      end

      context 'when block seat overages is enabled' do
        before do
          stub_feature_flags(block_seat_overages: true)
        end

        it 'returns true when there is a seat overage' do
          group.add_developer(create(:user))

          expect(component.render?).to eq(true)
        end

        it 'returns false when there is not a seat overage' do
          expect(component.render?).to eq(false)
        end
      end

      context 'when block seat overages is disabled' do
        before do
          stub_feature_flags(block_seat_overages: false)
        end

        it 'returns false even when there is a seat overage' do
          group.add_developer(create(:user))

          expect(component.render?).to eq(false)
        end

        it 'returns false when there is not a seat overage' do
          expect(component.render?).to eq(false)
        end
      end
    end
  end

  describe 'rendering', :saas do
    before_all do
      create(:gitlab_subscription, :premium, namespace: group, seats: 1)

      group.add_developer(create(:user))
      group.add_developer(create(:user))
    end

    before do
      stub_feature_flags(block_seat_overages: true)

      synchronous_reactive_cache(group)
    end

    context 'with the group owner' do
      before_all do
        group.add_owner(current_user)
      end

      it 'renders a banner for the owner' do
        render_inline(component)

        expect(page).not_to have_css('[data-testid="close-icon"]')
        expect(page).to have_text "Your top-level group #{group.name} is now read-only."
        expect(page).to have_text "#{group.name} has exceeded the number of seats in its subscription " \
                                  "and is now read-only. To remove the read-only state, reduce the number of users " \
                                  "in your top-level group to make seats available, or purchase more seats for " \
                                  "the subscription."
        expect(page).to have_link 'read-only', href: help_page_path('user/read_only_namespaces')
        expect(page).to have_link 'Manage members', href: group_usage_quotas_path(group, anchor: 'seats-quota-tab')
        subscription_portal_url = ::Gitlab::Routing.url_helpers.subscription_portal_url
        add_seats_href = "#{subscription_portal_url}/gitlab/namespaces/#{group.id}/extra_seats"
        expect(page).to have_link 'Purchase more seats', href: add_seats_href
      end
    end

    context 'with a non-group owner' do
      before_all do
        group.add_developer(current_user)
      end

      it 'renders a banner for non-owners' do
        render_inline(component)

        expect(page).not_to have_css('[data-testid="close-icon"]')
        expect(page).to have_text "The top-level group #{group.name} is now read-only."
        expect(page).to have_text "To remove the read-only state, ask a user with the Owner role for " \
                                  "#{group.name} to reduce the number of users in the group, or to purchase more " \
                                  "seats for the subscription."
        expect(page).to have_link 'read-only', href: help_page_path('user/read_only_namespaces')
        expect(page).not_to have_link 'Manage members'
      end
    end
  end

  def component(resource = group)
    described_class.new(resource: resource, content_class: '', current_user: current_user)
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate
