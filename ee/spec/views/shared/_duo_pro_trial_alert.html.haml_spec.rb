# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_duo_pro_trial_alert', :saas, feature_category: :code_suggestions do
  let(:user) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate -- requires for checking owner access
  let(:group) { create(:group_with_plan, plan: :ultimate_plan) } # rubocop:todo RSpec/FactoryBot/AvoidCreate -- requires for checking owner access

  before do
    group.add_owner(user)
    allow(view).to receive(:resource).and_return(group)
    allow(view).to receive(:current_user).and_return(user)
  end

  it_behaves_like 'duo pro trial alert', 'shared/duo_pro_trial_alert'
end
