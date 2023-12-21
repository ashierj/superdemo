# frozen_string_literal: true

require 'fileutils'
require 'cgi'
require 'httparty'
require 'json'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will locate any featrure flag definition file
  # that were added at least `<CUTOFF_MILESTONE_OLD> milestones` ago and remove the definition file.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -r keeps/delete_old_feature_flags.rb \
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

        next unless before_cuttoff?(feature_flag.milestone)

        # feature_flag_default_enabled = feature_flag_definition[:default_enabled]
        # feature_flag_gitlab_com_state = fetch_gitlab_com_state(feature_flag.name)

        # TODO: Handle the different cases of default_enabled vs enabled/disabled on GitLab.com

        # # Finalize the migration
        title = "Delete the `#{feature_flag.name}` feature flag introduced in #{feature_flag.milestone}"

        identifiers = [self.class.name.demodulize, feature_flag.name]

        # rubocop:disable Gitlab/DocUrl -- Not running inside rails application
        description = <<~MARKDOWN
        This feature flag was introduced more than #{CUTOFF_MILESTONE_OLD} milestones ago.

        As part of our process we want to ensure [feature flags don't stay too long in the codebase](https://docs.gitlab.com/ee/development/feature_flags/#types-of-feature-flags).

        <details><summary>Mentions of the feature flag (click to expand)</summary>

        ```
        #{feature_flag_grep(feature_flag.name)}
        ```

        </details>

        Labels to set (not yet automated): ~"#{feature_flag.group}"

        This merge request was created using the
        [gitlab-housekeeper](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139492)
        gem.
        #{assign_command(feature_flag.rollout_issue_url)}
        MARKDOWN
        # rubocop:enable Gitlab/DocUrl

        FileUtils.rm(feature_flag_yaml_file)

        changed_files = [feature_flag_yaml_file]

        to_create = ::Gitlab::Housekeeper::Change.new(identifiers, title, description, changed_files)
        yield(to_create)
      end
    end

    def before_cuttoff?(milestone)
      Gem::Version.new(milestone) < Gem::Version.new(milestone_ago(current_milestone, CUTOFF_MILESTONE_OLD))
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

    def current_milestone
      milestone = File.read(File.expand_path('../VERSION', __dir__))
      milestone.gsub(/^(\d+\.\d+).*$/, '\1').chomp
    end

    def milestone_ago(milestone, num_milestones)
      major, minor = milestone.split(".").map(&:to_i)

      older_major =
        if minor >= num_milestones
          major
        else
          major - (((num_milestones - minor - 1) / 13) + 1)
        end

      older_minor = (0..12).to_a[(minor - num_milestones) % 13]

      [older_major, older_minor].join(".")
    end

    def assign_command(rollout_issue_url)
      rollout_issue = get_rollout_issue(rollout_issue_url)
      return unless rollout_issue

      "/assign #{assignees(rollout_issue)}"
    end

    def assignees(rollout_issue)
      rollout_issue[:assignees].map { |assignee| "@#{assignee[:username]}" }.join(' ')
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
  end
end
# rubocop:enable Gitlab/Json
# rubocop:enable Gitlab/HTTParty
