# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.selfManagedAddOnEligibleUsers', feature_category: :seat_cost_management do
  include GraphqlHelpers
  let_it_be(:code_suggestions) { create(:gitlab_subscription_add_on) }

  let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, add_on: code_suggestions) }
  let(:query_add_on_purchase_ids) { [global_id_of(add_on_purchase)] }

  let(:query_fields) do
    query_graphql_field(:nodes, {}, [
      'id',
      query_graphql_field(:add_on_assignments, { add_on_purchase_ids: query_add_on_purchase_ids }, [
        query_graphql_field(:nodes, {}, [
          query_graphql_field(:add_on_purchase, {}, %w[id name])
        ])
      ])
    ])
  end

  let(:query) do
    graphql_query_for(
      :selfManagedAddOnEligibleUsers,
      { addOnType: :CODE_SUGGESTIONS },
      query_fields
    )
  end

  shared_examples 'not authorized' do
    it 'returns not authorized' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data).to eq({ "selfManagedAddOnEligibleUsers" => nil })
      expect(graphql_errors).to include(a_hash_including(
        'message' => "The resource that you are attempting to access does not exist " \
                     "or you don't have permission to perform this action"
      ))
    end
  end

  describe 'authorization' do
    context 'on a self-managed instance' do
      before do
        stub_saas_features(code_suggestions: false) # !Gitlab.com?
      end

      context 'with owner access' do
        let_it_be(:current_user) { create(:user) }

        let_it_be(:group) { create(:group) }
        let_it_be(:owner) { create(:user) }

        before_all do
          group.add_owner(current_user)
        end

        include_examples 'not authorized'
      end
    end

    context 'with an admin on SaaS/GitLab.com' do
      let_it_be(:current_user) { create(:admin) }

      before do
        stub_saas_features(code_suggestions: true) # Gitlab.com?
      end

      include_examples 'not authorized'
    end
  end

  context 'when the current user is authorised to query users' do
    let_it_be(:current_user) { create(:admin) }

    let_it_be(:guest_user) { create(:user, name: 'Guest Group User') }
    let_it_be(:active_user) { create(:user, name: 'Active Group User') }
    let_it_be(:active_user_2) { create(:user, name: 'GitlabX') }

    before do
      stub_saas_features(code_suggestions: false)
    end

    before_all do
      add_on_purchase.namespace.add_owner(current_user)
      add_on_purchase.namespace.add_guest(guest_user)
      add_on_purchase.namespace.add_developer(active_user)

      create(:gitlab_subscription_user_add_on_assignment, user: current_user, add_on_purchase: add_on_purchase)
      create(:gitlab_subscription_user_add_on_assignment, user: guest_user, add_on_purchase: add_on_purchase)
      create(:gitlab_subscription_user_add_on_assignment, user: active_user, add_on_purchase: add_on_purchase)
    end

    context 'when the :self_managed_code_suggestions FF is disabled' do
      before do
        stub_feature_flags(self_managed_code_suggestions: false)
      end

      it 'returns an empty collection' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes)).to match_array([])
      end
    end

    context 'when there are search args' do
      let(:query) do
        graphql_query_for(
          :selfManagedAddOnEligibleUsers,
          { addOnType: :CODE_SUGGESTIONS, search: 'Group User' },
          query_fields
        )
      end

      it 'returns the add on eligible users and their assignments, filtered by search term' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes))
          .to match_array([
            {
              'id' => global_id_of(active_user).to_s,
              'addOnAssignments' => { 'nodes' => [expected_add_on_purchase_data(add_on_purchase)] }
            },
            {
              'id' => global_id_of(guest_user).to_s,
              'addOnAssignments' => { 'nodes' => [expected_add_on_purchase_data(add_on_purchase)] }
            }
          ])
      end

      it 'returns empty records if search term does not match any users' do
        query_without_results = graphql_query_for(
          :selfManagedAddOnEligibleUsers,
          { addOnType: :CODE_SUGGESTIONS, search: 'Nonexistent User' },
          query_fields
        )

        post_graphql(query_without_results, current_user: current_user)

        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes)).to be_empty
      end
    end

    context 'when there are no search args' do
      let_it_be(:bot) { create(:user, :bot) }
      let_it_be(:ghost) { create(:user, :ghost) }
      let_it_be(:blocked_user) { create(:user, :blocked) }
      let_it_be(:banned_user) { create(:user, :banned) }
      let_it_be(:pending_approval_user) { create(:user, :blocked_pending_approval) }

      it 'returns all the add on eligible users and their assignments' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes)).to match_array([
          {
            'id' => global_id_of(current_user).to_s,
            'addOnAssignments' => { 'nodes' => [expected_add_on_purchase_data(add_on_purchase)] }
          },
          {
            'id' => global_id_of(guest_user).to_s,
            'addOnAssignments' => { 'nodes' => [expected_add_on_purchase_data(add_on_purchase)] }
          },
          {
            'id' => global_id_of(active_user).to_s,
            'addOnAssignments' => { 'nodes' => [expected_add_on_purchase_data(add_on_purchase)] }
          },
          {
            'id' => global_id_of(active_user_2).to_s,
            'addOnAssignments' => { 'nodes' => [] }
          }
        ])
      end
    end

    context 'when there are multiple add-on eligible users' do
      it 'avoids N+1 database queries', :request_store do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes, :add_on_assignments, :nodes).count).to eq(3)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        additional_user = create(:user)
        add_on_purchase.namespace.add_guest(additional_user)
        create(:gitlab_subscription_user_add_on_assignment, user: additional_user, add_on_purchase: add_on_purchase)

        expect { post_graphql(query, current_user: current_user) }.to issue_same_number_of_queries_as(control)
        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes, :add_on_assignments, :nodes).count).to eq(4)
      end
    end

    context 'when selecting for multiple add on purchases' do
      let(:other_add_on_purchase) { create(:gitlab_subscription_add_on_purchase, add_on: code_suggestions) }

      let(:query_add_on_purchase_ids) do
        [global_id_of(add_on_purchase), global_id_of(other_add_on_purchase)]
      end

      before do
        other_add_on_purchase.namespace.add_owner(current_user)
      end

      it 'avoids N+1 database queries', :request_store do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes, :add_on_assignments, :nodes).count).to eq(3)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create(:gitlab_subscription_user_add_on_assignment, user: current_user, add_on_purchase: other_add_on_purchase)

        expect { post_graphql(query, current_user: current_user) }.to issue_same_number_of_queries_as(control)
        expect(graphql_data_at(:self_managed_add_on_eligible_users, :nodes, :add_on_assignments, :nodes).count).to eq(4)
      end
    end
  end

  def expected_add_on_purchase_data(expected_add_on_purchase)
    {
      'addOnPurchase' => { 'id' => global_id_of(expected_add_on_purchase).to_s, 'name' => 'CODE_SUGGESTIONS' }
    }
  end
end
