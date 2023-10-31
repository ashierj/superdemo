# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_admin', feature_category: :navigation do
  let(:user) { build_stubbed(:admin) }

  before do
    allow(user).to receive(:can_admin_all_resources?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'on templates settings' do
    before do
      stub_licensed_features(custom_file_templates: custom_file_templates)

      render
    end

    context 'license with custom_file_templates feature' do
      let(:custom_file_templates) { true }

      it 'includes Templates link' do
        expect(rendered).to have_link('Templates', href: '/admin/application_settings/templates')
      end
    end

    context 'license without custom_file_templates feature' do
      let(:custom_file_templates) { false }

      it 'does not include Templates link' do
        expect(rendered).not_to have_link('Templates', href: '/admin/application_settings/templates')
      end
    end
  end

  context 'on advanced search settings' do
    context 'license with elastic_search feature' do
      before do
        stub_licensed_features(elastic_search: true)
        render
      end

      it 'includes Advanced Search link' do
        expect(rendered).to have_link('Advanced Search', href: '/admin/application_settings/advanced_search')
      end
    end

    context 'elastic_search feature is available through usage ping features' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_usage_ping_features(true)
        render
      end

      it 'includes Advanced Search link' do
        expect(rendered).to have_link('Advanced Search', href: '/admin/application_settings/advanced_search')
      end
    end

    context 'license without elastic_search feature' do
      before do
        stub_licensed_features(elastic_search: false)
        render
      end

      it 'includes Advanced Search link' do
        expect(rendered).not_to have_link('Advanced Search', href: '/admin/application_settings/advanced_search')
      end
    end
  end
end
