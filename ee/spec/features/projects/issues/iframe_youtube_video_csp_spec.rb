# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Youtube iframe content security policy', feature_category: :activation do
  include ContentSecurityPolicyHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }

  subject(:csp_header) { response_headers['Content-Security-Policy'] }

  it 'includes content security policy headers' do
    sign_in(user)

    visit project_issues_path(project)

    expect(find_csp_directive('frame-src', header: csp_header)).to include(
      'https://www.youtube-nocookie.com'
    )
  end
end
