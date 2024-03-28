# frozen_string_literal: true

# rubocop:disable Style/RedundantRegexpEscape -- Several instances of this cop triggering in this file which are not justified as they're matching the escaped characters.

require 'spec_helper'

RSpec.describe ProductAnalytics::SyncFunnelsWorker, feature_category: :product_analytics_data_management do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:commit) { project.repository.commit }

  subject(:worker) { described_class.new.perform(project.id, commit.sha, user.id) }

  before do
    allow_next_instance_of(ProductAnalytics::Settings) do |settings|
      allow(settings).to receive(:product_analytics_configurator_connection_string).and_return('http://test:test@localhost:4567')
    end
  end

  before_all do
    create_valid_funnel
  end

  describe '#perform' do
    let(:expected_added) do
      {
        project_ids: [project.id],
        funnels: [
          {
            name: "completed_purchase",
            schema: an_instance_of(String),
            state: "added"
          }
        ]
      }
    end

    let(:expected_updated) do
      {
        project_ids: [project.id],
        funnels: [
          {
            name: "completed_purchase",
            schema: an_instance_of(String),
            state: "updated"
          }
        ]
      }
    end

    context 'when a new funnel is in the commit' do
      it 'is successful' do
        expect(Gitlab::HTTP).to receive(:post)
                .with('http://test:test@localhost:4567/funnel-schemas', {
                  allow_local_requests: true,
                  body: /\"state\":\"created\"/
                }).once
                .and_return(instance_double("HTTParty::Response", body: { result: 'success' }))

        worker
      end
    end

    context 'when an updated funnel is in the commit' do
      before do
        update_funnel
      end

      it 'is successful' do
        expect(Gitlab::HTTP)
          .to receive(:post)
                .with('http://test:test@localhost:4567/funnel-schemas', {
                  allow_local_requests: true,
                  body: /\"state\":\"updated\"/
                })
                .once
                .and_return(instance_double("HTTParty::Response", body: { result: 'success' }))

        worker
      end
    end

    context 'when an renamed funnel is in the commit' do
      before do
        rename_funnel
      end

      it 'is successful' do
        expect(Gitlab::HTTP)
          .to receive(:post)
                .with('http://test:test@localhost:4567/funnel-schemas', {
                  allow_local_requests: true,
                  body: /\"previous_name\":\"completed_purchase\"/
                })
                .once
                .and_return(instance_double("HTTParty::Response", body: { result: 'success' }))

        worker
      end
    end

    context 'when an deleted funnel is in the commit' do
      before do
        delete_funnel
      end

      it 'is successful' do
        expect(Gitlab::HTTP)
          .to receive(:post)
                .with('http://test:test@localhost:4567/funnel-schemas', {
                  allow_local_requests: true,
                  body: /\"state\":\"deleted\"/
                })
                .once
                .and_return(instance_double("HTTParty::Response", body: { result: 'success' }))

        worker
      end
    end

    context 'when no new or updated funnels are in the commit' do
      before do
        commit_with_no_funnel
      end

      it 'does not attempt to post to the API' do
        expect(Gitlab::HTTP).not_to receive(:post)

        worker
      end
    end
  end

  private

  def commit_with_no_funnel
    project.repository.create_file(
      project.creator,
      'readme.md',
      'test file',
      message: 'Add readme',
      branch_name: 'master'
    )
  end

  def create_valid_funnel
    project.repository.create_file(
      project.creator,
      '.gitlab/analytics/funnels/example1.yml',
      File.read(Rails.root.join('ee/spec/fixtures/product_analytics/funnel_example_1.yaml')),
      message: 'Add funnel',
      branch_name: 'master'
    )
  end

  def rename_funnel
    project.repository.update_file(
      project.creator,
      '.gitlab/analytics/funnels/example1.yml',
      File.read(Rails.root.join('ee/spec/fixtures/product_analytics/funnel_example_renamed.yaml')),
      message: 'Update funnel',
      branch_name: 'master'
    )
  end

  def update_funnel
    project.repository.update_file(
      project.creator,
      '.gitlab/analytics/funnels/example1.yml',
      File.read(Rails.root.join('ee/spec/fixtures/product_analytics/funnel_example_changed.yaml')),
      message: 'Update funnel',
      branch_name: 'master'
    )
  end

  def delete_funnel
    project.repository.delete_file(
      project.creator,
      '.gitlab/analytics/funnels/example1.yml',
      message: 'delete funnel',
      branch_name: 'master'
    )
  end
end

# rubocop:enable Style/RedundantRegexpEscape
