# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Trials::CreateDuoProService, feature_category: :purchase do
  let_it_be(:user, reload: true) { create(:user) }
  let(:step) { described_class::LEAD }

  describe '#execute' do
    let(:trial_params) { {} }
    let(:extra_lead_params) { {} }
    let(:trial_user_params) do
      { trial_user: lead_params(user, extra_lead_params) }
    end

    let(:lead_service_class) { GitlabSubscriptions::Trials::CreateDuoProLeadService }
    let(:apply_trial_service_class) { GitlabSubscriptions::Trials::ApplyDuoProService }

    subject(:execute) do
      described_class.new(
        step: step, lead_params: lead_params(user, extra_lead_params), trial_params: trial_params, user: user
      ).execute
    end

    it_behaves_like 'when on the lead step'
    it_behaves_like 'when on trial step'
    it_behaves_like 'with an unknown step'
    it_behaves_like 'with no step'
    it_behaves_like 'with tracking duo pro trial lead'
  end

  def lead_params(user, extra_lead_params)
    {
      company_name: 'GitLab',
      company_size: '1-99',
      first_name: user.first_name,
      last_name: user.last_name,
      phone_number: '+1 23 456-78-90',
      country: 'US',
      work_email: user.email,
      uid: user.id,
      setup_for_company: user.setup_for_company,
      skip_email_confirmation: true,
      gitlab_com_trial: true,
      provider: 'gitlab',
      product_interaction: 'duo_pro_trial',
      preferred_language: user.preferred_language,
      opt_in: user.onboarding_status_email_opt_in
    }.merge(extra_lead_params)
  end
end
