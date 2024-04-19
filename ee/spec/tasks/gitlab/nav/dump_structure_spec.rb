# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:nav:dump_structure', :silence_stdout, feature_category: :navigation do
  let!(:user) { create(:user) }

  before do
    # Build out scaffold records required for rake task
    create(:project)
    create(:group)
    create(:organization)

    Rake.application.rake_require 'tasks/gitlab/nav/dump_structure'
  end

  it 'outputs YAML describing the current nav structure' do
    # Sample items that _hopefully_ won't change very often.
    expected = {
      "generated_at" => an_instance_of(String),
      "commit_sha" => an_instance_of(String),
      "contexts" => a_collection_including(a_hash_including({
        "title" => "User profile navigation",
        "items" => a_collection_including(a_hash_including({
          "id" => "activity_menu",
          "title" => "Activity",
          "icon" => "history",
          "link" => "/users/#{user.username}/activity"
        }))
      }))
    }
    expect(YAML).to receive(:dump).with(expected)

    run_rake_task('gitlab:nav:dump_structure')
  end
end
