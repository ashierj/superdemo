# frozen_string_literal: true

module Types
  class SubscriptionType < ::Types::BaseObject
    graphql_name 'Subscription'

    field :issuable_assignees_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the assignees of an issuable are updated.'

    field :issue_crm_contacts_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the crm contacts of an issuable are updated.'

    field :issuable_title_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the title of an issuable is updated.'

    field :issuable_description_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the description of an issuable is updated.'

    field :issuable_labels_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the labels of an issuable are updated.'

    field :issuable_dates_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the due date or start date of an issuable is updated.'

    field :issuable_milestone_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the milestone of an issuable is updated.'

    field :work_item_note_created,
      subscription: ::Subscriptions::Notes::Created, null: true,
      description: 'Triggered when a note is created.',
      alpha: { milestone: '15.9' }

    field :work_item_note_deleted,
      subscription: ::Subscriptions::Notes::Deleted, null: true,
      description: 'Triggered when a note is deleted.',
      alpha: { milestone: '15.9' }

    field :work_item_note_updated,
      subscription: ::Subscriptions::Notes::Updated, null: true,
      description: 'Triggered when a note is updated.',
      alpha: { milestone: '15.9' }

    field :merge_request_reviewers_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the reviewers of a merge request are updated.'

    field :merge_request_merge_status_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when the merge status of a merge request is updated.'

    field :merge_request_approval_state_updated,
      subscription: Subscriptions::IssuableUpdated, null: true,
      description: 'Triggered when approval state of a merge request is updated.'
  end
end

Types::SubscriptionType.prepend_mod
