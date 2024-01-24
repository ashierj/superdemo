# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard issues', feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:page_path) { issues_dashboard_path }

  it_behaves_like 'dashboard ultimate trial callout'

  it_behaves_like 'dashboard SAML reauthentication banner'
end
