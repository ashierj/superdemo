# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project elastic search', :js, :elastic do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }

  before do
    stub_feature_flags(search_page_vertical_nav: false)
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe 'searching' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_path(project)
    end

    it 'finds issues' do
      create(:issue, project: project, title: 'Test searching for an issue')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Issues')

      expect(page).to have_selector('.results', text: 'Test searching for an issue')
    end

    it 'finds merge requests' do
      create(:merge_request, source_project: project, target_project: project, title: 'Test searching for an MR')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Merge requests')

      expect(page).to have_selector('.results', text: 'Test searching for an MR')
    end

    it 'finds milestones' do
      create(:milestone, project: project, title: 'Test searching for a milestone')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Milestones')

      expect(page).to have_selector('.results', text: 'Test searching for a milestone')
    end

    it 'finds wiki pages', :sidekiq_inline do
      project.wiki.create_page('test.md', 'Test searching for a wiki page')
      project.wiki.index_wiki_blobs
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Wiki')

      expect(page).to have_selector('.results', text: 'Test searching for a wiki page')
    end

    it 'finds notes' do
      create(:note, project: project, note: 'Test searching for a comment')
      ensure_elasticsearch_index!

      submit_search('Test')
      select_search_scope('Comments')

      expect(page).to have_selector('.results', text: 'Test searching for a comment')
    end

    it 'finds commits', :sidekiq_inline do
      project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!

      submit_search('initial')
      select_search_scope('Commits')

      expect(page).to have_selector('.results', text: 'Initial commit')
    end

    it 'finds blobs', :sidekiq_inline do
      project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!

      submit_search('def')
      select_search_scope('Code')

      expect(page).to have_selector('.results', text: 'def username_regex')
      expect(page).to have_button('Copy file path')
    end
  end

  describe 'displays Advanced Search status' do
    before do
      sign_in(user)

      visit search_path(project_id: project.id, repository_ref: repository_ref)
    end

    context "when `repository_ref` isn't the default branch" do
      let(:repository_ref) { Gitlab::Git::BLANK_SHA }

      it 'displays that advanced search is disabled' do
        expect(page).to have_selector('[data-testid="es-status-marker"][data-enabled="false"]')
        expect(page).to have_link('Learn more.', href: help_page_path('user/search/advanced_search', anchor: 'use-the-advanced-search-syntax'))
      end
    end

    context "when `repository_ref` is unset" do
      let(:repository_ref) { "" }

      it 'displays that advanced search is enabled' do
        expect(page).to have_selector('[data-testid="es-status-marker"][data-enabled="true"]')
      end
    end

    context "when `repository_ref` is the default branch" do
      let(:repository_ref) { project.default_branch }

      it 'displays that advanced search is enabled' do
        expect(page).to have_selector('[data-testid="es-status-marker"][data-enabled="true"]')
      end
    end
  end
end

RSpec.describe 'Project elastic search redactions', :elastic do
  before do
    stub_feature_flags(search_page_vertical_nav: false)
  end

  it_behaves_like 'a redacted search results page' do
    let(:search_path) { project_path(public_restricted_project) }
  end
end
