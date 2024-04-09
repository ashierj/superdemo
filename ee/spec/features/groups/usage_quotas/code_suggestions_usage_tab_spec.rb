# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas > Code Suggestions tab', :js, :saas, feature_category: :seat_cost_management do
  include SubscriptionPortalHelpers

  let(:user) { create(:user, first_name: 'Joe', last_name: 'Blow', organization: 'YMCA') }
  let(:group) { create(:group_with_plan, plan: :premium_plan) }

  before do
    stub_signing_key
    stub_application_setting(check_namespace_plan: true)
    stub_feature_flags(usage_quotas_for_all_editions: false)
    stub_subscription_permissions_data(group.id)

    group.add_owner(user)

    sign_in(user)
    visit group_usage_quotas_path(group, anchor: 'code-suggestions-usage-tab')
    wait_for_requests
  end

  context 'when user interactive with hand raise lead button' do
    it 'renders and submits in-app hand raise lead for code suggestions' do
      find_by_testid('code_suggestions_hand_raise_lead_button').click

      fill_in_and_submit_code_suggestions_hand_raise_lead
    end
  end

  context 'when bulk assign and unassign duo pro seats' do
    let_it_be(:group) { create(:group_with_plan, plan: :premium_plan) }

    context 'when user is owner' do
      before_all do
        group.add_developer(create(:user, username: 'developer_1'))
        group.add_developer(create(:user, username: 'developer_2'))
        group.add_developer(create(:user, username: 'developer_3'))
      end

      context 'when bulk assigning seats' do
        let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
        let_it_be(:add_on_purchase) do
          create(:gitlab_subscription_add_on_purchase, quantity: 10, namespace: group, add_on: add_on)
        end

        context 'when success' do
          it 'assigns the selected users' do
            expect(add_on_purchase.assigned_users.size).to eq(0)

            find_by_testid('select-all-users').click
            expect(find_by_testid('select-all-users')).to be_checked

            expect(page).to have_content('Assign seat')
            find_by_testid('assign-seats-button').click
            expect(page).to have_content('Confirm bulk seat allocation')
            expect(page).to have_content(
              'This action will assign a GitLab Duo Pro seat to 4 users. ' \
              'Are you sure you want to continue?'
            )

            find_by_testid('assign-confirmation-button').click
            wait_for_requests

            expect(page).to have_content('4 users have been successfully assigned a seat.')
            expect(add_on_purchase.reload.assigned_users.size).to eq(4)
          end
        end

        context 'when failed' do
          before_all do
            add_on_purchase.update!(quantity: 1)
          end

          it 'assigns the selected users' do
            expect(add_on_purchase.assigned_users).to eq([])

            find_by_testid('select-all-users').click
            expect(find_by_testid('select-all-users')).to be_checked

            find_by_testid('assign-seats-button').click

            find_by_testid('assign-confirmation-button').click
            wait_for_requests

            expect(page).to have_content('There are not enough seats to assign the GitLab Duo Pro add-on')
            expect(add_on_purchase.reload.assigned_users).to eq([])
          end
        end
      end

      context 'when bulk unassigning seats' do
        let_it_be(:users) { create_list(:user, 3) }
        let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
        let_it_be(:add_on_purchase) do
          create(:gitlab_subscription_add_on_purchase, quantity: 10, namespace: group, add_on: add_on)
        end

        before_all do
          users.each do |user|
            group.add_developer(user)
            create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: user)
          end
        end

        it 'unassigns the selected users' do
          expect(add_on_purchase.assigned_users.map(&:user)).to eq(users)

          find_by_testid('select-all-users').click
          expect(find_by_testid('select-all-users')).to be_checked

          expect(page).to have_content('Remove seat')
          find_by_testid('unassign-seats-button').click
          expect(page).to have_content('Confirm bulk seat unassignment')
          expect(page).to have_content(
            'This action will remove GitLab Duo Pro seats from 7 users. ' \
            'Are you sure you want to continue?'
          )

          find_by_testid('unassign-confirmation-button').click
          wait_for_requests

          expect(page).to have_content('7 users have been successfully unassigned a seat.')
          expect(add_on_purchase.reload.assigned_users).to eq([])
        end
      end
    end
  end

  def fill_in_and_submit_code_suggestions_hand_raise_lead
    form_data = {
      first_name: user.first_name,
      last_name: user.last_name,
      phone_number: '+1 23 456-78-90',
      company_size: '1 - 99',
      company_name: user.organization,
      country: { id: 'US', name: 'United States of America' },
      state: { id: 'CA', name: 'California' }
    }

    hand_raise_lead_params = {
      "first_name" => form_data[:first_name],
      "last_name" => form_data[:last_name],
      "company_name" => form_data[:company_name],
      "company_size" => form_data[:company_size].delete(' '),
      "phone_number" => form_data[:phone_number],
      "country" => form_data.dig(:country, :id),
      "state" => form_data.dig(:state, :id),
      "namespace_id" => group.id,
      "comment" => '',
      "glm_content" => 'code-suggestions',
      "product_interaction" => 'Requested Contact-Duo Pro Add-On',
      "work_email" => user.email,
      "uid" => user.id,
      "setup_for_company" => user.setup_for_company,
      "provider" => "gitlab",
      "glm_source" => 'gitlab.com'
    }

    expect_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
      expect(service).to receive(:execute).with(hand_raise_lead_params).and_return(instance_double('ServiceResponse',
        success?: true))
    end

    fill_hand_raise_lead_form_and_submit(form_data)
  end

  def fill_hand_raise_lead_form_and_submit(form_data)
    within_testid('hand-raise-lead-modal') do
      aggregate_failures do
        expect(page).to have_content('Contact our Sales team')
        expect(page).to have_field('First Name', with: form_data[:first_name])
        expect(page).to have_field('Last Name', with: form_data[:last_name])
        expect(page).to have_field('Company Name', with: form_data[:company_name])
      end

      select form_data[:company_size], from: 'company-size'
      fill_in 'phone-number', with: form_data[:phone_number]
      select form_data.dig(:country, :name), from: 'country'
      select form_data.dig(:state, :name), from: 'state'

      click_button 'Submit information'
    end
  end
end
