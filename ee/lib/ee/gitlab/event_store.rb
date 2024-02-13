# frozen_string_literal: true

module EE
  module Gitlab
    module EventStore
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override
        # Define event subscriptions using:
        #
        #   store.subscribe(DomainA::SomeWorker, to: DomainB::SomeEvent)
        #
        # It is possible to subscribe to a subset of events matching a condition:
        #
        #   store.subscribe(DomainA::SomeWorker, to: DomainB::SomeEvent), if: ->(event) { event.data == :some_value }
        #
        # Only EE subscriptions should be declared in this module.
        override :configure!
        def configure!(store)
          super(store)

          ###
          # Add EE only subscriptions here:

          store.subscribe ::Security::Scans::PurgeByJobIdWorker, to: ::Ci::JobArtifactsDeletedEvent
          store.subscribe ::Geo::CreateRepositoryUpdatedEventWorker,
            to: ::Repositories::KeepAroundRefsCreatedEvent,
            if: -> (_) { ::Gitlab::Geo.primary? }
          store.subscribe ::MergeRequests::StreamApprovalAuditEventWorker, to: ::MergeRequests::ApprovedEvent
          store.subscribe ::MergeRequests::ProcessApprovalAutoMergeWorker, to: ::MergeRequests::ApprovedEvent
          store.subscribe ::MergeRequests::CreateApprovalsResetNoteWorker, to: ::MergeRequests::ApprovalsResetEvent
          store.subscribe ::MergeRequests::ProcessApprovalAutoMergeWorker, to: ::MergeRequests::DraftStateChangeEvent
          store.subscribe ::MergeRequests::ProcessApprovalAutoMergeWorker, to: ::MergeRequests::UnblockedStateEvent
          store.subscribe ::PullMirrors::ReenableConfigurationWorker, to: ::GitlabSubscriptions::RenewedEvent
          store.subscribe ::Search::ElasticDefaultBranchChangedWorker,
            to: ::Repositories::DefaultBranchChangedEvent,
            if: -> (_) { ::Gitlab::CurrentSettings.elasticsearch_indexing? }
          store.subscribe ::Search::Zoekt::DefaultBranchChangedWorker, to: ::Repositories::DefaultBranchChangedEvent
          store.subscribe ::PackageMetadata::GlobalAdvisoryScanWorker, to: ::PackageMetadata::IngestedAdvisoryEvent
          store.subscribe ::Llm::NamespaceAccessCacheResetWorker, to: ::NamespaceSettings::AiRelatedSettingsChangedEvent
          store.subscribe ::Llm::NamespaceAccessCacheResetWorker, to: ::Members::MembersAddedEvent
          store.subscribe ::Security::RefreshProjectPoliciesWorker,
            to: ::ProjectAuthorizations::AuthorizationsChangedEvent,
            delay: 1.minute
          store.subscribe ::MergeRequests::RemoveUserApprovalRulesWorker,
            to: ::ProjectAuthorizations::AuthorizationsRemovedEvent
          store.subscribe ::Security::ScanResultPolicies::AddApproversToRulesWorker,
            to: ::ProjectAuthorizations::AuthorizationsAddedEvent
          store.subscribe ::Security::RefreshComplianceFrameworkSecurityPoliciesWorker,
            to: ::Projects::ComplianceFrameworkChangedEvent
          store.subscribe ::Sbom::ProcessTransferEventsWorker, to: ::Projects::ProjectTransferedEvent
          store.subscribe ::Sbom::ProcessTransferEventsWorker, to: ::Groups::GroupTransferedEvent
          store.subscribe ::Vulnerabilities::ProcessTransferEventsWorker,
            to: ::Projects::ProjectTransferedEvent,
            if: ->(event) {
                  ::Feature.enabled?(:update_vuln_reads_traversal_ids_via_event,
                    ::Project.find_by_id(event.data['project_id']), type: :gitlab_com_derisk)
                }
          store.subscribe ::Vulnerabilities::ProcessTransferEventsWorker,
            to: ::Groups::GroupTransferedEvent,
            if: ->(event) {
                  ::Feature.enabled?(:update_vuln_reads_traversal_ids_via_event,
                    ::Group.find_by_id(event.data['group_id']), type: :gitlab_com_derisk)
                }
        end
      end
    end
  end
end
