# frozen_string_literal: true

module Members
  class DestroyService < Members::BaseService
    include Gitlab::ExclusiveLeaseHelpers

    def execute(member, skip_authorization: false, skip_subresources: false, unassign_issuables: false, destroy_bot: false)
      unless skip_authorization
        raise Gitlab::Access::AccessDeniedError unless authorized?(member, destroy_bot)

        raise Gitlab::Access::AccessDeniedError if destroying_member_with_owner_access_level?(member) &&
          cannot_revoke_owner_responsibilities_from_member_in_project?(member)
      end

      @skip_auth = skip_authorization

      if a_group_owner?(member)
        process_destroy_of_group_owner_member(member, skip_subresources)
      else
        destroy_member(member)
        destroy_data_related_to_member(member, skip_subresources)
      end

      enqueue_jobs_that_needs_to_be_run_only_once_per_hierarchy(member, unassign_issuables)

      member
    end

    # We use this to mark recursive calls made to this service from within the same service.
    # We do this so as to help us run some tasks that needs to be run only once per hierarchy, and not recursively.
    def mark_as_recursive_call
      @recursive_call = true
    end

    private

    # These actions need to be executed only once per hierarchy because the underlying services
    # apply these actions to the entire hierarchy anyway, so there is no need to execute them recursively.
    def enqueue_jobs_that_needs_to_be_run_only_once_per_hierarchy(member, unassign_issuables)
      return if recursive_call?

      enqueue_delete_todos(member)
      enqueue_unassign_issuables(member) if unassign_issuables
    end

    def recursive_call?
      @recursive_call == true
    end

    def process_destroy_of_group_owner_member(member, skip_subresources)
      # Deleting 2 different group owners via the API in quick succession could lead to
      # wrong results for the `last_owner?` check due to race conditions. To prevent this
      # we wrap both the last_owner? check and the deletes of owners within a lock.
      last_group_owner = true

      in_lock("delete_members:#{member.source.class}:#{member.source.id}", sleep_sec: 0.1.seconds) do
        break if member.source.last_owner?(member.user)

        last_group_owner = false
        destroy_member(member)
      end

      # deletion of related data does not have to be within the lock.
      destroy_data_related_to_member(member, skip_subresources) unless last_group_owner
    end

    def destroy_member(member)
      member.destroy
    end

    def destroy_data_related_to_member(member, skip_subresources)
      member.user&.invalidate_cache_counts
      delete_member_associations(member, skip_subresources)
    end

    def a_group_owner?(member)
      member.is_a?(GroupMember) && member.owner?
    end

    def delete_member_associations(member, skip_subresources)
      if member.request? && member.user != current_user
        notification_service.decline_access_request(member)
      end

      delete_subresources(member) unless skip_subresources
      delete_project_invitations_by(member) unless skip_subresources
      resolve_access_request_todos(member)

      after_execute(member: member)
    end

    def authorized?(member, destroy_bot)
      return can_destroy_bot_member?(member) if destroy_bot

      if member.request?
        return can_destroy_member_access_request?(member) || can_withdraw_member_access_request?(member)
      end

      can_destroy_member?(member)
    end

    def delete_subresources(member)
      return unless member.is_a?(GroupMember) && member.user && member.group

      delete_project_members(member)
      delete_subgroup_members(member)
      delete_invited_members(member)
    end

    def delete_project_members(member)
      groups = member.group.self_and_descendants

      destroy_project_members(ProjectMember.in_namespaces(groups).with_user(member.user))
    end

    def delete_subgroup_members(member)
      groups = member.group.descendants

      destroy_group_members(GroupMember.of_groups(groups).with_user(member.user))
    end

    def delete_invited_members(member)
      groups = member.group.self_and_descendants

      destroy_group_members(GroupMember.of_groups(groups).not_accepted_invitations_by_user(member.user))

      destroy_project_members(ProjectMember.in_namespaces(groups).not_accepted_invitations_by_user(member.user))
    end

    def destroy_project_members(members)
      members.each do |project_member|
        service = self.class.new(current_user)
        service.mark_as_recursive_call
        service.execute(project_member, skip_authorization: @skip_auth)
      end
    end

    def destroy_group_members(members)
      members.each do |group_member|
        service = self.class.new(current_user)
        service.mark_as_recursive_call
        service.execute(group_member, skip_authorization: @skip_auth, skip_subresources: true)
      end
    end

    def delete_project_invitations_by(member)
      return unless member.is_a?(ProjectMember) && member.user && member.project

      members_to_delete = member.project.members.not_accepted_invitations_by_user(member.user)
      destroy_project_members(members_to_delete)
    end

    def can_destroy_member?(member)
      can?(current_user, destroy_member_permission(member), member)
    end

    def can_destroy_bot_member?(member)
      can?(current_user, destroy_bot_member_permission(member), member)
    end

    def can_destroy_member_access_request?(member)
      can?(current_user, :admin_member_access_request, member.source)
    end

    def can_withdraw_member_access_request?(member)
      can?(current_user, :withdraw_member_access_request, member)
    end

    def destroying_member_with_owner_access_level?(member)
      member.owner?
    end

    def destroy_member_permission(member)
      case member
      when GroupMember
        :destroy_group_member
      when ProjectMember
        :destroy_project_member
      else
        raise "Unknown member type: #{member}!"
      end
    end

    def destroy_bot_member_permission(member)
      raise "Unsupported bot member type: #{member}" unless member.is_a?(ProjectMember)

      :destroy_project_bot_member
    end

    def enqueue_unassign_issuables(member)
      source_type = member.is_a?(GroupMember) ? 'Group' : 'Project'

      member.run_after_commit_or_now do
        MembersDestroyer::UnassignIssuablesWorker.perform_async(member.user_id, member.source_id, source_type)
      end
    end
  end
end

Members::DestroyService.prepend_mod_with('Members::DestroyService')
