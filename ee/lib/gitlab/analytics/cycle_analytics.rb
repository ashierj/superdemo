# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      extend Gitlab::Allowable

      class << self
        def licensed?(subject)
          case subject
          when Namespaces::ProjectNamespace
            project = subject.project
            # Only available within groups
            project.licensed_feature_available?(:cycle_analytics_for_projects) &&
              project.root_ancestor.group_namespace?
          when Group
            subject.licensed_feature_available?(:cycle_analytics_for_groups)
          else
            false
          end
        end

        def allowed?(user, subject)
          ability_allowed?(:read_cycle_analytics, user, subject)
        end

        def allowed_to_edit?(user, subject)
          ability_allowed?(:admin_value_stream, user, subject)
        end

        def subject_for_access_check(subject)
          case subject
          when Namespaces::ProjectNamespace
            subject.project
          when Group
            subject
          else
            raise ArgumentError, "Unsupported subject given"
          end
        end

        def ability_allowed?(ability, user, subject)
          case subject
          when Namespaces::ProjectNamespace, Group
            can?(user, ability, subject_for_access_check(subject))
          else
            false
          end
        end
      end
    end
  end
end
