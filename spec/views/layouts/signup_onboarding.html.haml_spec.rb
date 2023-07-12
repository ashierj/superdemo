# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/signup_onboarding' do
  it_behaves_like 'a layout which reflects the application theme setting'
  it_behaves_like 'a layout which reflects the preferred language'
end
