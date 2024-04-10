# frozen_string_literal: true

RSpec.shared_examples_for 'duo pro trial alert' do |path|
  subject { view.content_for(:page_level_alert) }

  context 'when duo_pro_trial_alert feature flag is enabled' do
    it 'renders the duo pro trial alert' do
      # Just `render` throws a "no implicit conversion of nil into String" exception in the case of early return in view
      # https://github.com/rails/rails/issues/41320
      view.render(path)

      expect(subject).to have_text(s_('DuoProTrialAlert|Try GitLab Duo Pro for free'))
      expect(subject).to have_link(s_('DuoProTrialAlert|Start trial now'),
        href: new_trials_duo_pro_path(namespace_id: group.id))
      expect(subject).to have_link(s_('DuoProTrialAlert|Learn more about GitLab Duo Pro'),
        href: help_page_path('user/ai_features'))
    end
  end

  context 'when duo_pro_trial_alert feature flag is disabled' do
    before do
      stub_feature_flags(duo_pro_trial_alert: false)
    end

    it 'does not render the duo pro trial alert' do
      view.render(path)

      expect(subject).not_to have_text(s_('DuoProTrialAlert|Try GitLab Duo Pro for free'))
    end
  end
end
