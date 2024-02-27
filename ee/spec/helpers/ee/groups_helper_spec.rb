# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsHelper, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let(:owner) { create(:user, group_view: :security_dashboard) }
  let(:current_user) { owner }
  let(:group) { create(:group, :private) }

  before do
    allow(helper).to receive(:current_user) { current_user }
    helper.instance_variable_set(:@group, group)

    group.add_owner(owner)
  end

  describe '#render_setting_to_allow_project_access_token_creation?' do
    context 'with self-managed' do
      let_it_be(:parent) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent) }

      before do
        parent.add_owner(owner)
        group.add_owner(owner)
      end

      it 'returns true if group is root' do
        expect(helper.render_setting_to_allow_project_access_token_creation?(parent)).to eq(true)
      end

      it 'returns false if group is subgroup' do
        expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to eq(false)
      end
    end

    context 'on .com', :saas do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'with a free plan' do
        let_it_be(:group) { create(:group) }

        it 'returns false' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to eq(false)
        end
      end

      context 'with a paid plan' do
        let_it_be(:parent) { create(:group_with_plan, plan: :bronze_plan) }
        let_it_be(:group) { create(:group, parent: parent) }

        before do
          parent.add_owner(owner)
        end

        it 'returns true if group is root' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(parent)).to eq(true)
        end

        it 'returns false if group is subgroup' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to eq(false)
        end
      end
    end
  end

  describe '#permanent_deletion_date' do
    let(:date) { 2.days.from_now }

    subject { helper.permanent_deletion_date(date) }

    before do
      stub_application_setting(deletion_adjourned_period: 5)
    end

    it 'returns the sum of the date passed as argument and the deletion_adjourned_period set in application setting' do
      expected_date = date + 5.days

      expect(subject).to eq(expected_date.strftime('%F'))
    end
  end

  describe '#remove_group_message' do
    subject { helper.remove_group_message(group) }

    shared_examples 'permanent deletion message' do
      it 'returns the message related to permanent deletion' do
        expect(subject).to include("You are going to remove #{group.name}")
        expect(subject).to include("Removed groups CANNOT be restored!")
      end
    end

    shared_examples 'delayed deletion message' do
      it 'returns the message related to delayed deletion' do
        expect(subject).to include("The contents of this group, its subgroups and projects will be permanently removed after")
      end
    end

    context 'delayed deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it_behaves_like 'delayed deletion message'

      context 'group is already marked for deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: Date.current)
        end

        it_behaves_like 'permanent deletion message'
      end

      context 'when group delay deletion is enabled' do
        before do
          stub_application_setting(delayed_group_deletion: true)
        end

        it_behaves_like 'delayed deletion message'
      end

      context 'when group delay deletion is disabled' do
        before do
          stub_application_setting(delayed_group_deletion: false)
        end

        it_behaves_like 'delayed deletion message'
      end

      context 'when group delay deletion is enabled and adjourned deletion period is 0' do
        before do
          stub_application_setting(delayed_group_deletion: true)
          stub_application_setting(deletion_adjourned_period: 0)
        end

        it_behaves_like 'permanent deletion message'
      end
    end

    context 'delayed deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it_behaves_like 'permanent deletion message'
    end
  end

  describe '#immediately_remove_group_message' do
    subject { helper.immediately_remove_group_message(group) }

    it 'returns the message related to immediate deletion' do
      expect(subject).to match(/permanently remove.*#{group.path}.*immediately/)
    end
  end

  describe '#show_discover_group_security?' do
    using RSpec::Parameterized::TableSyntax

    where(
      gitlab_com?: [true, false],
      user?: [true, false],
      security_dashboard_feature_available?: [true, false],
      can_admin_group?: [true, false]
    )

    with_them do
      it 'returns the expected value' do
        allow(helper).to receive(:current_user) { user? ? owner : nil }
        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(group).to receive(:licensed_feature_available?) { security_dashboard_feature_available? }
        allow(helper).to receive(:can?) { can_admin_group? }

        expected_value = user? && gitlab_com? && !security_dashboard_feature_available? && can_admin_group?

        expect(helper.show_discover_group_security?(group)).to eq(expected_value)
      end
    end
  end

  describe '#show_group_activity_analytics?' do
    before do
      stub_licensed_features(group_activity_analytics: feature_available)

      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
    end

    context 'when feature is not available for group' do
      let(:feature_available) { false }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when current user does not have access to the group' do
      let(:feature_available) { true }
      let(:current_user) { create(:user) }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when feature is available and user has access to it' do
      let(:feature_available) { true }

      it 'returns true' do
        expect(helper.show_group_activity_analytics?).to be true
      end
    end
  end

  describe '#show_user_cap_alert?' do
    before do
      allow(group).to receive(:user_cap_available?).and_return(user_cap_applied)
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    describe 'when user cap is available' do
      let(:user_cap_applied) { true }

      describe 'when user cap value is set' do
        before do
          group.namespace_settings.update!(new_user_signups_cap: 10)
        end

        describe 'when user is an owner of the root namespace' do
          it { expect(helper.show_user_cap_alert?).to be true }
        end

        describe 'when user is not an owner of the root namespace' do
          let(:current_user) { create(:user) }

          it { expect(helper.show_user_cap_alert?).to be false }
        end
      end

      describe 'when user cap value is not set' do
        before do
          group.namespace_settings.update!(new_user_signups_cap: nil)
        end

        describe 'when user is an owner of the root namespace' do
          it { expect(helper.show_user_cap_alert?).to be false }
        end
      end

      context 'when namespace settings is nil' do
        let(:group) { build(:group) }

        it { expect(helper.show_user_cap_alert?).to be false }
      end
    end

    describe 'when user cap is not available' do
      let(:user_cap_applied) { false }

      it { expect(helper.show_user_cap_alert?).to be false }
    end
  end

  describe '#pending_members_link' do
    it { expect(helper.pending_members_link).to eq link_to('', pending_members_group_usage_quotas_path(group)) }

    describe 'for a sub-group' do
      let(:sub_group) { create(:group, :private, parent: group) }

      before do
        helper.instance_variable_set(:@group, sub_group)
      end

      it 'returns a link to the root group' do
        expect(helper.pending_members_link).to eq link_to('', pending_members_group_usage_quotas_path(group))
      end
    end
  end

  describe '#show_product_purchase_success_alert?' do
    describe 'when purchased_product is present' do
      before do
        allow(controller).to receive(:params) { { purchased_product: product } }
      end

      where(:product, :result) do
        'product' | true
        ''        | false
        nil       | false
      end

      with_them do
        it { expect(helper.show_product_purchase_success_alert?).to be result }
      end
    end

    describe 'when purchased_product is not present' do
      it { expect(helper.show_product_purchase_success_alert?).to be false }
    end
  end

  describe '#group_seats_usage_quota_app_data' do
    subject(:group_seats_usage_quota_app_data) { helper.group_seats_usage_quota_app_data(group) }

    let(:enforcement_free_user_cap) { false }
    let(:data) do
      {
        namespace_id: group.id,
        namespace_name: group.name,
        is_public_namespace: group.public?.to_s,
        full_path: group.full_path,
        seat_usage_export_path: group_seat_usage_path(group, format: :csv),
        add_seats_href: ::Gitlab::Routing.url_helpers.subscription_portal_add_extra_seats_url(group.id),
        has_no_subscription: group.has_free_or_no_subscription?.to_s,
        max_free_namespace_seats: 10,
        explore_plans_path: group_billings_path(group),
        enforcement_free_user_cap_enabled: 'false'
      }
    end

    before do
      stub_ee_application_setting(dashboard_limit: 10)

      expect_next_instance_of(::Namespaces::FreeUserCap::Enforcement, group) do |instance|
        expect(instance).to receive(:enforce_cap?).and_return(enforcement_free_user_cap)
      end
    end

    context 'when free user cap is enforced' do
      let(:enforcement_free_user_cap) { true }
      let(:expected_data) { data.merge({ enforcement_free_user_cap_enabled: 'true' }) }

      it { is_expected.to eql(expected_data) }
    end

    context 'when is private namespace' do
      let(:expected_data) { data.merge({ is_public_namespace: 'false' }) }

      it { is_expected.to eql(expected_data) }
    end

    context 'when is public namespace' do
      let_it_be(:group) { create(:group, :public) }

      let(:expected_data) { data.merge({ is_public_namespace: 'true' }) }

      it { is_expected.to eql(expected_data) }
    end
  end

  describe '#code_suggestions_usage_app_data' do
    subject(:code_suggestions_usage_app_data) { helper.code_suggestions_usage_app_data(group) }

    let(:data) do
      {
        full_path: group.full_path,
        group_id: group.id,
        add_duo_pro_href: ::Gitlab::Routing.url_helpers.subscription_portal_add_saas_duo_pro_seats_url(group.id)
      }
    end

    context 'when cs_connect_with_sales ff is disabled' do
      before do
        stub_feature_flags(cs_connect_with_sales: false)
      end

      it { is_expected.to eql(data) }
    end

    context 'when cs_connect_with_sales ff is enabled' do
      it 'contains data for hand raise lead button' do
        hand_raise_lead_button_data = helper.code_suggestions_hand_raise_props(group)

        expect(subject).to eq(data.merge(hand_raise_lead_button_data))
      end
    end
  end

  describe '#product_analytics_usage_quota_app_data' do
    subject(:product_analytics_usage_quota_app_data) { helper.product_analytics_usage_quota_app_data(group) }

    before do
      allow(helper).to receive(:image_path).and_return('illustrations/chart-empty-state.svg')
    end

    let(:data) do
      {
        namespace_path: group.full_path,
        empty_state_illustration_path: "illustrations/chart-empty-state.svg"
      }
    end

    context 'when product analytics is disabled' do
      before do
        stub_application_setting(product_analytics_enabled?: false)
      end

      it { is_expected.to eql(data.merge({ product_analytics_enabled: "false" })) }
    end

    context 'when product analytics is enabled' do
      before do
        stub_application_setting(product_analytics_enabled?: true)
      end

      it { is_expected.to eql(data.merge({ product_analytics_enabled: "true" })) }
    end
  end

  describe '#hand_raise_props' do
    let_it_be(:user) { create(:user, username: 'Joe', first_name: 'Joe', last_name: 'Doe', organization: 'ACME') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'builds correct hash' do
      props = helper.hand_raise_props(group, glm_content: 'some-content')

      expect(props).to eq(
        namespace_id: group.id,
        user_name: 'Joe',
        first_name: 'Joe',
        last_name: 'Doe',
        company_name: 'ACME',
        glm_content: 'some-content',
        product_interaction: 'Hand Raise PQL',
        create_hand_raise_lead_path: '/-/subscriptions/hand_raise_leads')
    end

    it 'allows overriding of the default product_interaction' do
      props = helper.hand_raise_props(group, glm_content: 'some-content', product_interaction: '_product_interaction_')

      expect(props).to include(product_interaction: '_product_interaction_')
    end
  end

  describe '#code_suggestions_hand_raise_props' do
    let(:user) { build(:user, username: 'Joe', first_name: 'Joe', last_name: 'Doe', organization: 'ACME') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'builds correct hash' do
      expected_result = {
        namespace_id: group.id,
        user_name: 'Joe',
        first_name: 'Joe',
        last_name: 'Doe',
        company_name: 'ACME',
        glm_content: 'code-suggestions',
        product_interaction: 'Requested Contact-Code Suggestions Add-On',
        create_hand_raise_lead_path: '/-/subscriptions/hand_raise_leads',
        track_action: 'click_button',
        track_label: 'code_suggestions_hand_raise_lead_form',
        button_attributes:
          {
            'data-testid': 'code_suggestions_hand_raise_lead_button',
            category: 'tertiary',
            variant: 'confirm'
          }.to_json
      }

      props = helper.code_suggestions_hand_raise_props(group)

      expect(props).to eq(expected_result)
    end
  end

  describe '#code_suggestions_owner_alert_hand_raise_props' do
    let(:user) { build(:user, username: 'Joe', first_name: 'Joe', last_name: 'Doe', organization: 'ACME') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'builds correct hash' do
      expected_result = {
        namespace_id: group.id,
        user_name: 'Joe',
        first_name: 'Joe',
        last_name: 'Doe',
        company_name: 'ACME',
        glm_content: 'code-suggestions',
        product_interaction: 'Requested Contact-Code Suggestions owner alert',
        create_hand_raise_lead_path: '/-/subscriptions/hand_raise_leads',
        dismiss_feature_id: ::EE::Users::CalloutsHelper::CODE_SUGGESTIONS_GA_OWNER_ALERT,
        button_text: s_('CodeSuggestionsGAAlert|Contact Sales'),
        button_attributes: {
          variant: 'confirm',
          'data-testid': 'code_suggestions_owner_alert_hand_raise_lead_button'
        }.to_json,
        track_action: 'click_button',
        track_label: 'cs_group_owner_alert'
      }

      props = helper.code_suggestions_owner_alert_hand_raise_props(group)

      expect(props).to eq(expected_result)
    end
  end

  describe '#show_code_suggestions_tab?' do
    context 'on saas' do
      before do
        stub_saas_features(gitlab_com_subscriptions: true)
        allow(group).to receive(:has_free_or_no_subscription?) { has_free_or_no_subscription? }
      end

      context 'when hamilton_seat_management is enabled' do
        where(:has_free_or_no_subscription?, :result) do
          true  | false
          false | true
        end
        with_them do
          it { expect(helper.show_code_suggestions_tab?(group)).to eq(result) }
        end
      end

      context 'when hamilton_seat_management is disabled' do
        before do
          stub_feature_flags(hamilton_seat_management: false)
        end

        where(:has_free_or_no_subscription?, :result) do
          true  | false
          false | false
        end

        with_them do
          it { expect(helper.show_code_suggestions_tab?(group)).to eq(result) }
        end
      end
    end

    context 'on self managed' do
      before do
        stub_saas_features(gitlab_com_subscriptions: false)
        stub_feature_flags(self_managed_code_suggestions: true)
      end

      it { expect(helper.show_code_suggestions_tab?(group)).to be_falsy }
    end
  end

  describe '#saml_sso_settings_generate_helper_text' do
    let(:text) { 'some text' }
    let(:result) { "<span class=\"js-helper-text gl-clearfix\">#{text}</span>" }

    specify { expect(helper.saml_sso_settings_generate_helper_text(display_none: false, text: text)).to eq result }
    specify { expect(helper.saml_sso_settings_generate_helper_text(display_none: true, text: text)).to include('gl-display-none') }
  end

  describe '#group_transfer_app_data' do
    it 'returns expected hash' do
      expect(helper.group_transfer_app_data(group)).to eq({
        full_path: group.full_path
      })
    end
  end

  describe '#subgroup_creation_data' do
    subject { helper.subgroup_creation_data(group) }

    context 'when self-managed' do
      it { is_expected.to include(is_saas: 'false') }
    end

    context 'when on .com', :saas do
      it { is_expected.to include(is_saas: 'true') }
    end
  end

  describe '#can_admin_service_accounts?', feature_category: :user_management do
    it 'returns true when current_user can admin members' do
      stub_licensed_features(service_accounts: true)

      expect(helper.can_admin_service_accounts?(group)).to be(true)
    end

    it 'returns false when current_user can not admin members' do
      expect(helper.can_admin_service_accounts?(group)).to be(false)
    end
  end

  describe '#access_level_roles_user_can_assign' do
    subject { helper.access_level_roles_user_can_assign(group) }

    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:user) { create(:user) }

    context 'when user is provided' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'when a user is a group member' do
        before do
          group.add_developer(user)
        end

        context 'when the minimal access role is available' do
          before do
            stub_licensed_features(minimal_access_role: true)
          end

          it 'includes the minimal access role' do
            expect(subject).to eq(
              {
                'Minimal Access' => 5,
                'Guest' => 10,
                'Reporter' => 20,
                'Developer' => 30
              }
            )
          end
        end
      end
    end
  end
end
