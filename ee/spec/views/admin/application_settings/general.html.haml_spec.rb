# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/general.html.haml' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:admin) }
  let_it_be(:app_settings) { build(:application_setting) }

  let(:code_suggestions_start_date) { CodeSuggestions::SelfManaged::SERVICE_START_DATE }
  let(:before_code_suggestions_start_date) { code_suggestions_start_date - 1.second }
  let(:after_code_suggestions_start_date) { code_suggestions_start_date + 1.second }

  let(:duo_chat_cut_off_date) { code_suggestions_start_date + 1.month }
  let(:before_duo_chat_cut_off_date) { duo_chat_cut_off_date - 1.second }
  let(:after_duo_chat_cut_off_date) { duo_chat_cut_off_date + 1.second }

  let(:duo_chat) { CloudConnector::ConnectedService.new(name: :duo_chat, cut_off_date: duo_chat_cut_off_date) }

  subject { rendered }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:current_user).and_return(user)

    allow_next_instance_of(::CloudConnector::AccessService) do |instance|
      allow(instance).to receive(:available_services).and_return({ duo_chat: duo_chat })
    end
  end

  describe 'maintenance mode' do
    let(:license_allows) { true }

    before do
      allow(Gitlab::Geo).to receive(:license_allows?).and_return(license_allows)

      render
    end

    context 'when license does not allow' do
      let(:license_allows) { false }

      it 'does not show the Maintenance mode section' do
        expect(rendered).not_to have_css('#js-maintenance-mode-toggle')
      end
    end

    context 'when license allows' do
      it 'shows the Maintenance mode section' do
        expect(rendered).to have_css('#js-maintenance-mode-toggle')
      end
    end
  end

  describe 'SAML group locks settings' do
    let(:saml_group_sync_enabled) { false }
    let(:settings_text) { 'SAML group membership settings' }

    before do
      allow(view).to receive(:saml_group_sync_enabled?).and_return(saml_group_sync_enabled)

      render
    end

    it { is_expected.not_to match(settings_text) }

    context 'when one or multiple SAML providers are group-sync-enabled' do
      let(:saml_group_sync_enabled) { true }

      it { is_expected.to match(settings_text) }
    end
  end

  describe 'prompt user about registration features' do
    context 'with no license and service ping disabled' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'renders registration features prompt', :application_setting_disabled_repository_size_limit
      it_behaves_like 'renders registration features settings link'
    end

    context 'with a valid license and service ping disabled' do
      let(:current_license) { build(:license) }

      before do
        allow(License).to receive(:current).and_return(current_license)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'does not render registration features prompt', :application_setting_disabled_repository_size_limit
    end
  end

  describe 'add license' do
    let(:current_license) { build(:license) }

    before do
      assign(:new_license, current_license)
      render
    end

    it 'shows the Add License section' do
      expect(rendered).to have_css('#js-add-license-toggle')
    end
  end

  describe 'sign-up restrictions' do
    it 'does not render complexity setting attributes' do
      render

      expect(rendered).to match 'id="js-signup-form"'
      expect(rendered).not_to match 'data-password-lowercase-required'
    end

    context 'when password_complexity license is available' do
      before do
        stub_licensed_features(password_complexity: true)
      end

      it 'renders complexity setting attributes' do
        render

        expect(rendered).to match ' data-password-lowercase-required='
        expect(rendered).to match ' data-password-number-required='
      end
    end
  end

  describe 'product analytics settings' do
    shared_examples 'renders nothing' do
      it do
        render

        expect(rendered).not_to have_css '#js-product-analytics-settings'
      end
    end

    shared_examples 'renders the settings' do
      it do
        render

        expect(rendered).to have_css '#js-product-analytics-settings'
        expect(rendered).to have_css "[data-name='application_setting[product_analytics_configurator_connection_string]']"
        expect(rendered).to have_field s_('AdminSettings|Collector host')
        expect(rendered).to have_field s_('AdminSettings|Cube API URL')
        expect(rendered).to have_css "[data-name='application_setting[cube_api_key]']"
      end
    end

    where(:licensed, :flag_enabled, :examples_to_run) do
      true    | true  | 'renders the settings'
      false   | true  | 'renders nothing'
      true    | false | 'renders nothing'
      false   | false | 'renders nothing'
    end

    with_them do
      before do
        stub_licensed_features(product_analytics: licensed)
        stub_feature_flags(product_analytics_admin_settings: flag_enabled)
      end

      it_behaves_like params[:examples_to_run]
    end
  end

  describe 'instance-level Code Suggestions settings', feature_category: :code_suggestions do
    before do
      allow(::Gitlab).to receive(:org_or_com?).and_return(gitlab_org_or_com?)
      stub_licensed_features(code_suggestions: false)
    end

    shared_examples 'does not render Code Suggestions toggle' do
      it 'does not render Code Suggestions toggle' do
        render
        expect(rendered).not_to have_field('application_setting_instance_level_code_suggestions_enabled')
      end
    end

    context 'when on .com or .org' do
      let(:gitlab_org_or_com?) { true }

      it_behaves_like 'does not render Code Suggestions toggle'
    end

    context 'when not on .com and not on .org' do
      let(:gitlab_org_or_com?) { false }

      context 'with license', :with_license do
        context 'with :code_suggestions feature available' do
          before do
            stub_licensed_features(code_suggestions: true)
          end

          # TODO: clean up date-related tests after the Code Suggestions service start date (16.9+)
          context 'when before the service start date' do
            around do |example|
              travel_to(CodeSuggestions::SelfManaged::SERVICE_START_DATE - 1.day) do
                example.run
              end
            end

            it 'renders Code Suggestions toggle' do
              render
              expect(rendered).to have_field('application_setting_instance_level_code_suggestions_enabled')
            end
          end

          context 'when at the service start date' do
            around do |example|
              travel_to(CodeSuggestions::SelfManaged::SERVICE_START_DATE) do
                example.run
              end
            end

            it_behaves_like 'does not render Code Suggestions toggle'
          end
        end

        context 'with :code_suggestions feature not available' do
          before do
            stub_licensed_features(code_suggestions: false)
          end

          it_behaves_like 'does not render Code Suggestions toggle'
        end
      end

      context 'with no license', :without_license do
        it_behaves_like 'does not render Code Suggestions toggle'
      end
    end
  end

  describe 'instance-level ai-powered beta features settings', feature_category: :duo_chat do
    before do
      allow(::Gitlab).to receive(:org_or_com?).and_return(gitlab_org_or_com?)
      stub_licensed_features(ai_chat: false)
    end

    shared_examples 'does not render AI Beta features toggle' do
      it 'does not render AI Beta features toggle' do
        render
        expect(rendered).not_to have_field('application_setting_instance_level_ai_beta_features_enabled')
      end
    end

    context 'when on .com or .org' do
      let(:gitlab_org_or_com?) { true }

      it_behaves_like 'does not render AI Beta features toggle'
    end

    context 'when not on .com and not on .org' do
      let(:gitlab_org_or_com?) { false }

      context 'with license', :with_license do
        context 'with :ai_chat feature available' do
          before do
            stub_licensed_features(ai_chat: true)
          end

          context 'when before the cut off date date' do
            around do |example|
              travel_to(duo_chat_cut_off_date - 1.day) do
                example.run
              end
            end

            it 'renders AI Beta features toggle' do
              render
              expect(rendered).to have_field('application_setting_instance_level_ai_beta_features_enabled')
            end
          end

          context 'when after the cut off date' do
            around do |example|
              travel_to(duo_chat_cut_off_date + 1.second) do
                example.run
              end
            end

            it 'does not render AI Beta features toggle' do
              render
              expect(rendered).not_to have_field('application_setting_instance_level_ai_beta_features_enabled')
            end
          end

          context 'when cut off date is nil' do
            let(:duo_chat_cut_off_date) { nil }

            around do |example|
              travel_to(before_code_suggestions_start_date) do
                example.run
              end
            end

            it 'renders AI Beta features toggle' do
              render
              expect(rendered).to have_field('application_setting_instance_level_ai_beta_features_enabled')
            end
          end
        end

        context 'with :ai_chat feature not available' do
          before do
            stub_licensed_features(ai_chat: false)
          end

          it_behaves_like 'does not render AI Beta features toggle'
        end
      end

      context 'with no license', :without_license do
        it_behaves_like 'does not render AI Beta features toggle'
      end
    end
  end

  # Tests specific license-related UI change that happens on the Code Suggestions service start date:
  # (internal) https://gitlab.com/gitlab-org/gitlab/-/issues/425047#note_1673643291
  # TODO: clean-up after the Code Suggestions service start date (16.9+)
  describe 'entire instance-level ai-powered menu section visibility', feature_category: :duo_chat do
    where(:current_date, :ai_chat_available, :code_suggestions_available, :expect_section_is_visible) do
      ref(:before_code_suggestions_start_date) | false | false | false
      ref(:before_code_suggestions_start_date) | false | true  | true
      ref(:before_code_suggestions_start_date) | true  | false | true
      ref(:before_code_suggestions_start_date) | true  | true  | true
      ref(:after_code_suggestions_start_date)  | false | false | false
      ref(:after_code_suggestions_start_date)  | false | true  | false
      ref(:after_code_suggestions_start_date)  | true  | false | true
      ref(:after_code_suggestions_start_date)  | true  | true  | true
      ref(:after_duo_chat_cut_off_date)        | false | false | false
      ref(:after_duo_chat_cut_off_date)        | false | true  | false
      ref(:after_duo_chat_cut_off_date)        | true  | false | false
      ref(:after_duo_chat_cut_off_date)        | true  | true  | false
    end

    with_them do
      it 'sets entire ai-powered menu section visibility correctly' do
        allow(::Gitlab).to receive(:org_or_com?).and_return(false)
        stub_licensed_features(ai_chat: ai_chat_available, code_suggestions: code_suggestions_available)

        travel_to(current_date) do
          render

          if expect_section_is_visible
            expect(rendered).to have_content('AI-powered features')
          else
            expect(rendered).not_to have_content('AI-powered features')
          end
        end
      end
    end
  end
end
