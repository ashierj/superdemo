# frozen_string_literal: true

module Backup
  module Tasks
    class CiSecureFiles < Task
      def human_name = _('ci secure files')

      def destination_path = 'ci_secure_files.tar.gz'

      def task
        excludes = ['tmp']

        Files.new(progress, app_files_dir, options: options, excludes: excludes)
      end

      private

      def app_files_dir
        Settings.ci_secure_files.storage_path
      end
    end
  end
end
