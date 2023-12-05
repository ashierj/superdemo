# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SsoHelper, feature_category: :shared do
  describe '#authorize_gma_conversion_confirm_modal_data' do
    let_it_be(:group_name) { 'Foo bar' }
    let_it_be(:phrase) { 'gma_user' }
    let_it_be(:remove_form_id) { 'js-authorize-gma-conversion-form' }

    subject { helper.authorize_gma_conversion_confirm_modal_data(group_name: group_name, phrase: phrase, remove_form_id: remove_form_id) }

    it 'returns expected hash' do
      expect(subject).to eq({
        remove_form_id: remove_form_id,
        button_text: _("Transfer ownership"),
        button_class: 'gl-w-full',
        confirm_danger_message: "You are about to transfer the control of your account to #{group_name} group. This action is NOT reversible, you won't be able to access any of your groups and projects outside of #{group_name} once this transfer is complete.",
        phrase: phrase
      })
    end
  end

  describe '#saml_provider_enabled' do
    using RSpec::Parameterized::TableSyntax
    context 'without group' do
      it 'returns false' do
        expect(helper.saml_provider_enabled?(nil)).to be false
        expect(helper.saml_provider_enabled?(build(:user_namespace))).to be false
        expect(helper.saml_provider_enabled?(build(:project))).to be false
      end
    end

    context 'with group' do
      where(:enabled, :result) do
        true  | true
        false | false
      end

      with_them do
        it 'returns the expected value' do
          provider = instance_double('SamlProvider')
          allow(provider).to receive(:enabled?) { enabled }

          group = instance_double('Group')
          allow(group).to receive(:is_a?).and_return(true)
          allow(group).to receive(:root_ancestor) { group }
          allow(group).to receive(:saml_provider) { provider }

          expect(helper.saml_provider_enabled?(group)).to eq(result)
        end
      end
    end
  end
end
