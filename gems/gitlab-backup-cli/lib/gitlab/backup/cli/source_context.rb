# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      # This context is equivalent to a Source Install or GDK instance
      #
      # Any specific information from the GitLab installation will be
      # automatically discovered from the current machine
      class SourceContext
        def gitlab_version
          # TODO: decouple from Rails codebase
          Gitlab::VERSION
        end

        def backup_basedir
          # TODO: decouple from Rails codebase, load from gitlab.yml file
          Rails.root.join('tmp/backups')
        end
      end
    end
  end
end
