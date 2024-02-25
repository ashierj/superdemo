# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        class BackupSubcommand < Command
          package_name 'Backup'

          desc 'all', 'Creates a backup including repositories, database and local files'
          def all
            duration = measure_duration do
              Gitlab::Backup::Cli::Output.info("Initializing environment...")
              Gitlab::Backup::Cli.rails_environment!
            end
            Gitlab::Backup::Cli::Output.info("Environment loaded. (#{duration.in_seconds}s)")

            duration = measure_duration do
              Gitlab::Backup::Cli::Output.info("Starting GitLab backup...")
              # TODO: perform backup here...
              sleep(1)
            end
            Gitlab::Backup::Cli::Output.info("Backup finished. (#{duration.in_seconds}s)")
          end

          private

          def measure_duration
            start = Time.now
            yield

            ActiveSupport::Duration.build(Time.now - start)
          end
        end
      end
    end
  end
end
