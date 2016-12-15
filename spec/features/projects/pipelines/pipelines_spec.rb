require 'spec_helper'
require 'rails_helper'

describe "Pipelines", feature: true, js: true do
  include GitlabRoutingHelper
  include WaitForVueResource

  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  before do
    login_as(user)
    project.team << [user, :developer]
  end

  describe 'GET /:project/pipelines', feature: true, js: true do
    include WaitForVueResource

    let(:project) { create(:project) }
    let!(:pipeline) do
      create(
        :ci_empty_pipeline,
        project: project,
        ref: 'master',
        status: 'running',
        sha: project.commit.id,
      )
    end

    [:all, :running, :branches].each do |scope|
      context "displaying #{scope}" do
        before do
          visit namespace_project_pipelines_path(
            project.namespace,
            project, scope: scope
          )
          wait_for_vue_resource
        end

        it do
          expect(page).to have_content(pipeline.short_sha)
        end
      end
    end

    context 'anonymous access' do
      before do
        visit namespace_project_pipelines_path(project.namespace, project)
        wait_for_vue_resource
      end

      it { expect(page).to have_http_status(:success) }
    end

    context 'cancelable pipeline' do
      let!(:build) do
        create(:ci_build, pipeline: pipeline, stage: 'test', commands: 'test')
      end

      before do
        build.run
        visit namespace_project_pipelines_path(project.namespace, project)
        wait_for_vue_resource
      end

      it { expect(page).to have_link('Cancel') }

      it { expect(page).to have_selector('.ci-running') }

      context 'when canceling' do
        before do
          wait_for_vue_resource
          click_link('Cancel')
        end

        it { expect(page).not_to have_link('Cancel') }

        it { expect(page).to have_selector('.ci-canceled') }
      end
    end

    context 'retryable pipelines' do
      let!(:build) do
        create(:ci_build, pipeline: pipeline, stage: 'test', commands: 'test')
      end

      before do
        build.drop
        visit namespace_project_pipelines_path(project.namespace, project)
      end

      it { expect(page).to have_link('Retry') }
      it { expect(page).to have_selector('.ci-failed') }

      context 'when retrying' do
        before do
          wait_for_vue_resource
          click_link('Retry')
        end

        it { expect(page).not_to have_link('Retry') }
        it { expect(page).to have_selector('.ci-running') }
      end
    end

    context 'with manual actions' do
      let!(:manual) do
        create(
          :ci_build,
          :manual,
          pipeline: pipeline,
          name: 'manual build',
          stage: 'test',
          commands: 'test'
        )
      end

      before do
        visit namespace_project_pipelines_path(project.namespace, project)
        wait_for_vue_resource
      end

      it { expect(page).to have_selector('.dropdown-toggle.btn.btn-default .icon-play') }

      context 'when playing' do
        before do
          wait_for_vue_resource
          find('.js-pipeline-dropdown-manual-actions').click
          click_link('Manual build')
        end

        it { expect(manual.reload).to be_pending }
      end
    end

    context 'for generic statuses' do
      context 'when running' do
        let!(:running) do
          create(
            :generic_commit_status,
            status: 'running',
            pipeline: pipeline,
            stage: 'test'
          )
        end

        before do
          visit namespace_project_pipelines_path(project.namespace, project)
          wait_for_vue_resource
        end

        it 'is cancelable' do
          expect(page).to have_link('Cancel')
        end

        it 'has pipeline running' do
          expect(page).to have_selector('.ci-running')
        end

        context 'when canceling' do
          before { click_link('Cancel') }

          it { expect(page).not_to have_link('Cancel') }
          it { expect(page).to have_selector('.ci-canceled') }
        end
      end

      context 'when failed' do
        let!(:status) do
          create(
            :generic_commit_status,
            :pending,
            pipeline: pipeline,
            stage: 'test'
          )
        end

        before do
          status.drop
          visit namespace_project_pipelines_path(project.namespace, project)
        end

        it 'is not retryable' do
          expect(page).not_to have_link('Retry')
        end

        it 'has failed pipeline' do
          expect(page).to have_selector('.ci-failed')
        end
      end
    end

    context 'downloadable pipelines' do
      context 'with artifacts' do
        let!(:with_artifacts) do
          create(
            :ci_build,
            :artifacts,
            :success,
            pipeline: pipeline,
            name: 'rspec tests',
            stage: 'test'
          )
        end

        before do
          visit namespace_project_pipelines_path(project.namespace, project)
        end

        it do
          wait_for_vue_resource
          expect(page).to have_selector('.build-artifacts')
        end

        it do
          wait_for_vue_resource
          find('.js-pipeline-dropdown-download').click
          expect(page).to have_link(with_artifacts.name)
        end
      end

      context 'with artifacts expired' do
        let!(:with_artifacts_expired) do
          create(
            :ci_build,
            :artifacts_expired,
            :success,
            pipeline: pipeline,
            name: 'rspec',
            stage: 'test'
          )
        end

        before do
          visit namespace_project_pipelines_path(project.namespace, project)
        end

        it { expect(page).not_to have_selector('.build-artifacts') }
      end

      context 'without artifacts' do
        let!(:without_artifacts) do
          create(
            :ci_build,
            :success,
            pipeline: pipeline,
            name: 'rspec',
            stage: 'test'
          )
        end

        before do
          visit namespace_project_pipelines_path(project.namespace, project)
        end

        it { expect(page).not_to have_selector('.build-artifacts') }
      end
    end
  end

  describe 'POST /:project/pipelines', feature: true, js: true do
    let(:project) { create(:project) }

    before do
      visit new_namespace_project_pipeline_path(project.namespace, project)
    end

    context 'for valid commit' do
      before { fill_in('pipeline[ref]', with: 'master') }

      context 'with gitlab-ci.yml' do
        before { stub_ci_pipeline_to_return_yaml_file }

        it 'creates a new pipeline' do
          expect { click_on 'Create pipeline' }
            .to change { Ci::Pipeline.count }.by(1)
        end
      end

      context 'without gitlab-ci.yml' do
        before { click_on 'Create pipeline' }

        it { expect(page).to have_content('Missing .gitlab-ci.yml file') }
      end
    end

    context 'for invalid commit' do
      before do
        fill_in('pipeline[ref]', with: 'invalid-reference')
        click_on 'Create pipeline'
      end

      it { expect(page).to have_content('Reference not found') }
    end
  end

  describe 'Create pipelines', feature: true, js: true do
    let(:project) { create(:project) }

    before do
      visit new_namespace_project_pipeline_path(project.namespace, project)
    end

    describe 'new pipeline page' do
      it 'has field to add a new pipeline' do
        expect(page).to have_field('pipeline[ref]')
        expect(page).to have_content('Create for')
      end
    end

    describe 'find pipelines' do
      it 'shows filtered pipelines', js: true do
        fill_in('pipeline[ref]', with: 'fix')
        find('input#ref').native.send_keys(:keydown)

        within('.ui-autocomplete') do
          expect(page).to have_selector('li', text: 'fix')
        end
      end
    end
  end
end
