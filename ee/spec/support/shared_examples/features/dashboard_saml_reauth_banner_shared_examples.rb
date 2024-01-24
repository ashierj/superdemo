# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples_for 'dashboard SAML reauthentication banner' do
  let_it_be(:restricted_group) { create(:group, :private) }
  let_it_be(:saml_provider) { create(:saml_provider, group: restricted_group, enabled: true, enforced_sso: true) }

  before do
    stub_licensed_features(group_saml: true)
  end

  before_all do
    create(:group_saml_identity, user: user, saml_provider: saml_provider)

    restricted_group.add_developer(user)

    sign_in(user)
  end

  context 'and the session is not active' do
    it 'shows the user an alert', :aggregate_failures do
      visit page_path

      expect(page).to have_content(
        s_('GroupSAML|Some items may be hidden because your SAML session has expired. Select the group’s path to reauthenticate and view any hidden items.') # rubocop:disable Layout/LineLength -- Single string
      )

      expect(page).to have_link(restricted_group.path, href: /#{sso_group_saml_providers_path(restricted_group)}/)
    end
  end

  context 'and the session is active' do
    before do
      dummy_session = { active_group_sso_sign_ins: { saml_provider.id => DateTime.now } }
      allow(Gitlab::Session).to receive(:current).and_return(dummy_session)
    end

    it 'does not show the user an alert', :aggregate_failures do
      visit page_path

      expect(page).not_to have_content(
        s_('GroupSAML|Some items may be hidden because your SAML session has expired. Select the group’s path to reauthenticate and view any hidden items.') # rubocop:disable Layout/LineLength -- Single string
      )
    end
  end
end
