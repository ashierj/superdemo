# frozen_string_literal: true

module Backup
  module Tasks
    class Lfs < Task
      def human_name = _('lfs objects')

      def destination_path = 'lfs.tar.gz'

      def task
        Files.new(progress, app_files_dir, options: options)
      end

      private

      def app_files_dir
        Settings.lfs.storage_path
      end
    end
  end
end
