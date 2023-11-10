# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/edit' do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(
      current_user: user,
      can?: true,
      current_application_settings: Gitlab::CurrentSettings.current_application_settings
    )
  end

  describe 'prompt user about registration features' do
    context 'with no license and service ping disabled' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'renders registration features prompt', :project_disabled_repository_size_limit
      it_behaves_like 'renders registration features settings link'
    end

    context 'with a valid license and service ping disabled' do
      before do
        license = build(:license)
        allow(License).to receive(:current).and_return(license)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'does not render registration features prompt', :project_disabled_repository_size_limit
    end
  end

  context 'when rendering for a user that is not an owner' do
    let_it_be(:user) { create(:user) }

    before do
      allow(view).to receive(:can?).with(user, :archive_project, project).and_return(can_archive_projects)
      render
    end

    subject { rendered }

    context 'when the user can archive projects' do
      let(:can_archive_projects) { true }

      it { is_expected.to have_link(_('Archive project')) }
    end

    context 'when the user cannot archive projects' do
      let(:can_archive_projects) { false }

      it { is_expected.not_to have_link(_('Archive project')) }
    end
  end
end
