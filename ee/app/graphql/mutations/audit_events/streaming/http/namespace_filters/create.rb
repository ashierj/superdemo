# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module HTTP
        module NamespaceFilters
          class Create < BaseMutation
            graphql_name 'AuditEventsStreamingHTTPNamespaceFiltersAdd'
            authorize :admin_external_audit_events

            argument :destination_id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
              required: true,
              description: 'Destination ID.'

            argument :group_path, GraphQL::Types::ID,
              required: false,
              description: 'Full path of the group.'

            argument :project_path, GraphQL::Types::ID,
              required: false,
              description: 'Full path of the project.'

            field :namespace_filter, ::Types::AuditEvents::Streaming::HTTP::NamespaceFilterType,
              null: true,
              description: 'Namespace filter created.'

            def ready?(**args)
              if args.slice(*mutually_exclusive_args).size != 1
                arg_str = mutually_exclusive_args.map { |x| x.to_s.camelize(:lower) }.join(' or ')
                raise Gitlab::Graphql::Errors::ArgumentError, "one and only one of #{arg_str} is required"
              end

              super
            end

            def resolve(args)
              destination = authorized_find!(args[:destination_id])

              namespace = namespace(args[:group_path], args[:project_path])

              filter = ::AuditEvents::Streaming::HTTP::NamespaceFilter
                         .new(external_audit_event_destination: destination,
                           namespace: namespace)

              audit(filter, action: :create) if filter.save

              { namespace_filter: (filter if filter.persisted?), errors: Array(filter.errors) }
            end

            private

            def find_object(destination_id)
              ::GitlabSchema.object_from_id(destination_id, expected_type: ::AuditEvents::ExternalAuditEventDestination)
            end

            def namespace(group_path, project_path)
              if group_path.present?
                namespace = ::Group.find_by_full_path(group_path)
                raise_resource_not_available_error! 'group_path is invalid' if namespace.nil?
                return namespace
              end

              namespace = ::Project.find_by_full_path(project_path)
              raise_resource_not_available_error! 'project_path is invalid' if namespace.nil?
              namespace.project_namespace
            end

            def audit(filter, action:)
              audit_context = {
                name: "#{action}_http_namespace_filter",
                author: current_user,
                scope: filter.external_audit_event_destination.group,
                target: filter.external_audit_event_destination,
                message: "#{action.capitalize} namespace filter for http audit event streaming destination " \
                         "#{filter.external_audit_event_destination.name} and namespace #{filter.namespace.full_path}"
              }

              ::Gitlab::Audit::Auditor.audit(audit_context)
            end

            def mutually_exclusive_args
              [:group_path, :project_path]
            end
          end
        end
      end
    end
  end
end
