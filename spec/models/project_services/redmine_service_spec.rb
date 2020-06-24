# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedmineService do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    # if redmine is set in setting the urls are set to defaults
    # therefore the validation passes as the values are not nil
    before do
      settings = {
        'redmine' => {}
      }
      allow(Gitlab.config).to receive(:issues_tracker).and_return(settings)
    end

    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }
      it { is_expected.to validate_presence_of(:new_issue_url) }

      it_behaves_like 'issue tracker service URL attribute', :project_url
      it_behaves_like 'issue tracker service URL attribute', :issues_url
      it_behaves_like 'issue tracker service URL attribute', :new_issue_url
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
      it { is_expected.not_to validate_presence_of(:new_issue_url) }
    end
  end

  describe '.reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does allow # on the reference' do
      expect(described_class.reference_pattern.match('#123')[:issue]).to eq('123')
    end
  end
end
