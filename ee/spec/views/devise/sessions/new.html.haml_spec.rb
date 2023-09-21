# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/sessions/new' do
  before do
    view.instance_variable_set(:@arkose_labs_public_key, "arkose-api-key")
    view.instance_variable_set(:@arkose_labs_domain, "gitlab-api.arkoselab.com")
  end

  describe 'broadcast messaging' do
    before do
      stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)
      stub_devise
      disable_captcha

      render
    end

    context 'when self-hosted' do
      let(:should_check_namespace_plan) { false }

      it { expect(rendered).to render_template('layouts/_broadcast') }
    end

    context 'when SaaS' do
      let(:should_check_namespace_plan) { true }

      it { expect(rendered).not_to render_template('layouts/_broadcast') }
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end

  def disable_captcha
    allow(view).to receive(:captcha_enabled?).and_return(false)
    allow(view).to receive(:captcha_on_login_required?).and_return(false)
  end
end
