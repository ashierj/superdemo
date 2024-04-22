# frozen_string_literal: true

# Gitlab::Access module
#
# Define allowed roles that can be used
# in GitLab code to determine authorization level
#
module Gitlab
  module Access
    AccessDeniedError = Class.new(StandardError)

    NO_ACCESS      = 0
    MINIMAL_ACCESS = 5
    GUEST          = 10
    REPORTER       = 20
    DEVELOPER      = 30
    MAINTAINER     = 40
    OWNER          = 50
    ADMIN          = 60

    # Branch protection settings
    PROTECTION_NONE          = 0
    PROTECTION_DEV_CAN_PUSH  = 1
    PROTECTION_FULL          = 2
    PROTECTION_DEV_CAN_MERGE = 3
    PROTECTION_DEV_CAN_INITIAL_PUSH = 4

    # Default project creation level
    NO_ONE_PROJECT_ACCESS = 0
    MAINTAINER_PROJECT_ACCESS = 1
    DEVELOPER_MAINTAINER_PROJECT_ACCESS = 2

    # Default subgroup creation level
    OWNER_SUBGROUP_ACCESS = 0
    MAINTAINER_SUBGROUP_ACCESS = 1

    class << self
      delegate :values, to: :options

      def all_values
        options_with_owner.values
      end

      def options
        {
          "Guest" => GUEST,
          "Reporter" => REPORTER,
          "Developer" => DEVELOPER,
          "Maintainer" => MAINTAINER
        }
      end

      def options_with_owner
        options.merge(
          "Owner" => OWNER
        )
      end

      def options_with_none
        options_with_owner.merge(
          "None" => NO_ACCESS
        )
      end

      def sym_options
        {
          guest: GUEST,
          reporter: REPORTER,
          developer: DEVELOPER,
          maintainer: MAINTAINER
        }
      end

      def sym_options_with_owner
        sym_options.merge(owner: OWNER)
      end

      def sym_options_with_admin
        sym_options_with_owner.merge(admin: ADMIN)
      end

      def protection_options
        [
          {
            label: s_('DefaultBranchProtection|Not protected'),
            help_text: s_('DefaultBranchProtection|Both developers and maintainers can push new commits, force push, or delete the branch.'),
            value: PROTECTION_NONE
          },
          {
            label: s_('DefaultBranchProtection|Protected against pushes'),
            help_text: s_('DefaultBranchProtection|Developers cannot push new commits, but are allowed to accept merge requests to the branch. Maintainers can push to the branch.'),
            value: PROTECTION_DEV_CAN_MERGE
          },
          {
            label: s_('DefaultBranchProtection|Partially protected'),
            help_text: s_('DefaultBranchProtection|Both developers and maintainers can push new commits, but cannot force push.'),
            value: PROTECTION_DEV_CAN_PUSH
          },
          {
            label: s_('DefaultBranchProtection|Fully protected'),
            help_text: s_('DefaultBranchProtection|Developers cannot push new commits, but maintainers can. No one can force push.'),
            value: PROTECTION_FULL
          },
          {
            label: s_('DefaultBranchProtection|Fully protected after initial push'),
            help_text: s_('DefaultBranchProtection|Developers can push the initial commit to a repository, but none afterward. Maintainers can always push. No one can force push.'),
            value: PROTECTION_DEV_CAN_INITIAL_PUSH
          }
        ]
      end

      def protection_values
        protection_options.map { |option| option[:value] }
      end

      def human_access(access)
        options_with_owner.key(access)
      end

      def human_access_with_none(access)
        options_with_none.key(access)
      end

      def project_creation_options
        {
          s_('ProjectCreationLevel|No one') => NO_ONE_PROJECT_ACCESS,
          s_('ProjectCreationLevel|Maintainers') => MAINTAINER_PROJECT_ACCESS,
          s_('ProjectCreationLevel|Developers + Maintainers') => DEVELOPER_MAINTAINER_PROJECT_ACCESS
        }
      end

      def project_creation_string_options
        {
          'noone' => NO_ONE_PROJECT_ACCESS,
          'maintainer' => MAINTAINER_PROJECT_ACCESS,
          'developer' => DEVELOPER_MAINTAINER_PROJECT_ACCESS
        }
      end

      def project_creation_values
        project_creation_options.values
      end

      def project_creation_string_values
        project_creation_string_options.keys
      end

      def project_creation_level_name(name)
        project_creation_options.key(name)
      end

      def subgroup_creation_options
        {
          s_('SubgroupCreationlevel|Owners') => OWNER_SUBGROUP_ACCESS,
          s_('SubgroupCreationlevel|Maintainers') => MAINTAINER_SUBGROUP_ACCESS
        }
      end

      def subgroup_creation_string_options
        {
          'owner' => OWNER_SUBGROUP_ACCESS,
          'maintainer' => MAINTAINER_SUBGROUP_ACCESS
        }
      end

      def subgroup_creation_values
        subgroup_creation_options.values
      end

      def subgroup_creation_string_values
        subgroup_creation_string_options.keys
      end
    end

    def human_access
      Gitlab::Access.human_access(access_field)
    end

    def human_access_with_none
      Gitlab::Access.human_access_with_none(access_field)
    end

    def human_access_labeled
      "#{s_('Default role')}: #{human_access}"
    end

    def owner?
      access_field == OWNER
    end
  end
end

Gitlab::Access.prepend_mod_with('Gitlab::Access')
