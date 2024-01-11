# frozen_string_literal: true

module Backup
  module Tasks
    class Packages < Task
      def human_name = _('packages')

      def destination_path = 'packages.tar.gz'

      def task
        excludes = ['tmp']

        Files.new(progress, app_files_dir, options: options, excludes: excludes)
      end

      private

      def app_files_dir
        Settings.packages.storage_path
      end
    end
  end
end
