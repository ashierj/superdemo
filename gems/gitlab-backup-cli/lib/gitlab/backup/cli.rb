# frozen_string_literal: true

require 'active_support/all'
require 'rainbow/refinement'

module Gitlab
  module Backup
    # GitLab Backup CLI
    module Cli
      autoload :Commands, 'gitlab/backup/cli/commands'
      autoload :Dependencies, 'gitlab/backup/cli/dependencies'
      autoload :Output, 'gitlab/backup/cli/output'
      autoload :Runner, 'gitlab/backup/cli/runner'
      autoload :Shell, 'gitlab/backup/cli/shell'
      autoload :Utils, 'gitlab/backup/cli/utils'
      autoload :VERSION, 'gitlab/backup/cli/version'

      Error = Class.new(StandardError)

      def self.rails_environment!
        require APP_PATH

        Rails.application.require_environment!
        Rails.application.autoloaders
      end
    end
  end
end
