# frozen_string_literal: true

require 'fileutils'
require 'cgi'
require 'httparty'
require 'json'
require_relative './helpers/groups'
require_relative './helpers/milestones'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will locate any featrure flag definition file
  # that were added at least `<CUTOFF_MILESTONE_OLD> milestones` ago and remove the definition file.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::DeleteOldFeatureFlags
  # ```
  # rubocop:disable Gitlab/HTTParty -- Don't use GitLab dependencies
  # rubocop:disable Gitlab/Json -- Don't use GitLab dependencies
  class DeleteOldFeatureFlags < ::Gitlab::Housekeeper::Keep
    CUTOFF_MILESTONE_OLD = 12
    GREP_IGNORE = [
      'locale/',
      'db/structure.sql'
    ].freeze
    API_BASE_URI = 'https://gitlab.com/api/v4'
    ROLLOUT_ISSUE_URL_REGEX = %r{\Ahttps://gitlab\.com/(?<project_path>.*)/-/issues/(?<issue_iid>\d+)\z}

    FeatureFlag = Struct.new(
      :name,
      :feature_issue_url,
      :introduced_by_url,
      :rollout_issue_url,
      :milestone,
      :group,
      :type,
      :default_enabled,
      keyword_init: true
    )

    def initialize; end

    def each_change
      each_feature_flag do |feature_flag_yaml_file, feature_flag_definition|
        feature_flag = FeatureFlag.new(feature_flag_definition)

        if feature_flag.milestone.nil?
          puts "#{feature_flag.name} has no milestone set!"
          next
        end

        next unless milestones_helper.before_cuttoff?(
          milestone: feature_flag.milestone,
          milestones_ago: CUTOFF_MILESTONE_OLD)

        # feature_flag_default_enabled = feature_flag_definition[:default_enabled]
        # feature_flag_gitlab_com_state = fetch_gitlab_com_state(feature_flag.name)

        # TODO: Handle the different cases of default_enabled vs enabled/disabled on GitLab.com

        # # Finalize the migration
        change = ::Gitlab::Housekeeper::Change.new
        change.changelog_type = 'removed'
        change.title = "Delete the `#{feature_flag.name}` feature flag"
        change.identifiers = [self.class.name.demodulize, feature_flag.name]

        # rubocop:disable Gitlab/DocUrl -- Not running inside rails application
        change.description = <<~MARKDOWN
        This feature flag was introduced in #{feature_flag.milestone}, which is more than #{CUTOFF_MILESTONE_OLD} milestones ago.

        As part of our process we want to ensure [feature flags don't stay too long in the codebase](https://docs.gitlab.com/ee/development/feature_flags/#types-of-feature-flags).

        <details><summary>Mentions of the feature flag (click to expand)</summary>

        ```
        #{feature_flag_grep(feature_flag.name)}
        ```

        </details>
        MARKDOWN
        # rubocop:enable Gitlab/DocUrl

        FileUtils.rm(feature_flag_yaml_file)

        change.changed_files = [feature_flag_yaml_file]

        change.labels = [
          'maintenance::removal',
          'feature flag',
          feature_flag.group
        ]

        change.reviewers = assignees(feature_flag.rollout_issue_url)

        if change.reviewers.empty?
          group_data = groups_helper.group_for_group_label(feature_flag.group)

          change.reviewers = groups_helper.pick_reviewer(group_data, change.identifiers) if group_data
        end

        yield(change)
      end
    end

    def fetch_gitlab_com_state(feature_flag_name)
      # TBD
    end

    def feature_flag_grep(feature_flag_name)
      Gitlab::Housekeeper::Shell.execute(
        'git',
        'grep',
        '--heading',
        '--line-number',
        '--break',
        feature_flag_name,
        '--',
        *(GREP_IGNORE.map { |path| ":^#{path}" })
      )
    end

    def assignees(rollout_issue_url)
      rollout_issue = get_rollout_issue(rollout_issue_url)

      return unless rollout_issue && rollout_issue[:assignees]

      rollout_issue[:assignees]
    end

    def get_rollout_issue(rollout_issue_url)
      matches = ROLLOUT_ISSUE_URL_REGEX.match(rollout_issue_url)
      return unless matches

      response = HTTParty.get(
        "#{API_BASE_URI}/projects/#{CGI.escape(matches[:project_path])}/issues/#{matches[:issue_iid]}"
      )

      unless (200..299).cover?(response.code)
        raise Error,
          "Failed with response code: #{response.code} and body:\n#{response.body}"
      end

      JSON.parse(response.body, symbolize_names: true)
    end

    def each_feature_flag
      all_feature_flag_files.map do |f|
        yield(f, YAML.load_file(f, permitted_classes: [Symbol], symbolize_names: true))
      end
    end

    def all_feature_flag_files
      Dir.glob("{,ee/}config/feature_flags/{development,gitlab_com_derisk}/*.yml")
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def milestones_helper
      @milestones_helper ||= ::Keeps::Helpers::Milestones.new
    end
  end
end
# rubocop:enable Gitlab/Json
# rubocop:enable Gitlab/HTTParty
