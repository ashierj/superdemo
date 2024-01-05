# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record/migration'

module Gitlab
  module CustomRoles
    class CodeGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      REQUEST_SPEC_DIR = 'ee/spec/requests/custom_roles'

      desc 'This generator creates the basic code for implementing a new custom ability'

      source_root File.expand_path('templates', __dir__)

      class_option :ability, type: :string, required: true, desc: 'The name of the ability'

      def validate!
        raise ArgumentError, "ability yaml file is not yet defined" unless permission_definition
      end

      def create_add_ability_migration
        migration_template('../templates/ability_migration.rb.template', perm_migration_file_name)
      end

      def create_request_spec
        template 'request_spec.rb.template', request_spec_file_name
      end

      private

      def perm_migration_file_name
        File.join(db_migrate_path, "add_#{options[:ability]}_to_member_roles.rb")
      end

      def request_spec_file_name
        dir_path = "#{REQUEST_SPEC_DIR}/#{ability}"
        FileUtils.mkdir_p(dir_path)

        File.join(dir_path, "request_spec.rb")
      end

      def ability
        options[:ability]
      end

      def feature_category
        permission_definition[:feature_category]
      end

      def permission_definition
        MemberRole.all_customizable_permissions[ability.to_sym]
      end
    end
  end
end
