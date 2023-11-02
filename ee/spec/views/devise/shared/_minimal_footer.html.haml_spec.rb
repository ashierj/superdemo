# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_minimal_footer', feature_category: :acquisition do
  subject { render && rendered }

  it { is_expected.to have_link(_('Terms'), href: terms_path) }
  it { is_expected.to have_link(_('Privacy'), href: 'https://about.gitlab.com/privacy') }
  it { is_expected.to have_css('.js-language-switcher') }
end
