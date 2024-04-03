# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesMrsEmptyStateExperiment, :experiment, :saas, feature_category: :activation do
  let_it_be(:user) { create(:user) }
  let_it_be(:free_project) { create(:project) }
  let_it_be(:ultimate_project) { create(:project, :in_group) }

  let_it_be(:subscription) do
    create(:gitlab_subscription, :ultimate, namespace: ultimate_project.group)
  end

  shared_examples 'excluded_users' do
    it 'excludes signed out users' do
      expect(experiment(:issues_mrs_empty_state)).to exclude(user: nil, project: free_project)
      expect(experiment(:issues_mrs_empty_state)).not_to exclude(user: user, project: free_project)
    end

    it 'excludes empty projects and paid plans' do
      expect(experiment(:issues_mrs_empty_state)).to exclude(user: user, project: nil)
      expect(experiment(:issues_mrs_empty_state)).to exclude(user: user, project: ultimate_project)
      expect(experiment(:issues_mrs_empty_state)).not_to exclude(user: user, project: free_project)
    end
  end

  context 'with control experience' do
    before do
      stub_experiments(issues_mrs_empty_state: :control)
    end

    it 'registers control behavior' do
      expect(experiment(:issues_mrs_empty_state)).to register_behavior(:control).with(nil)
      expect { experiment(:issues_mrs_empty_state, user: user, project: free_project).run }.not_to raise_error
    end

    it_behaves_like 'excluded_users'
  end

  context 'with candidate experience' do
    before do
      stub_experiments(issues_mrs_empty_state: :candidate)
    end

    it 'registers candidate behavior' do
      expect(experiment(:issues_mrs_empty_state)).to register_behavior(:candidate).with(nil)
      expect { experiment(:issues_mrs_empty_state, user: user, project: free_project).run }.not_to raise_error
    end

    it_behaves_like 'excluded_users'
  end
end
