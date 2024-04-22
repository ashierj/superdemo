# frozen_string_literal: true

module GitlabSubscriptions
  module Trials
    class BaseCreateService
      LEAD = 'lead'
      TRIAL = 'trial'
      LEAD_FAILED = :lead_failed
      TRIAL_FAILED = :trial_failed
      NOT_FOUND = :not_found
      NAMESPACE_CREATE_FAILED = :namespace_create_failed
      NO_SINGLE_NAMESPACE = :no_single_namespace

      def initialize(step:, lead_params:, trial_params:, user:)
        @step = step
        @lead_params = lead_params
        @trial_params = trial_params
        @user = user
      end

      def execute
        case step
        when LEAD
          lead_flow
        when TRIAL
          trial_flow
        else
          # some bogus request with unknown step or no step
          not_found
        end
      end

      private

      PROVIDER = 'gitlab'

      attr_reader :user, :lead_params, :trial_params, :step, :namespace

      def lead_flow
        result = lead_service_class.new.execute({ trial_user: trial_user_params })

        if result.success?
          after_lead_success_hook
        else
          after_lead_error_hook(result)
        end
      end

      def after_lead_success_hook
        if single_eligible_namespace_for_trial?
          @namespace = namespaces_eligible_for_trial.first
          apply_trial_flow
        else
          # trigger new creation for next step...
          trial_selection_params = {
            step: TRIAL
          }.merge(lead_params.slice(:glm_content, :glm_source))
           .merge(trial_params.slice(:namespace_id))

          ServiceResponse.error(
            message: 'Lead created, but singular eligible namespace not present',
            reason: NO_SINGLE_NAMESPACE,
            payload: { trial_selection_params: trial_selection_params }
          )
        end
      end

      def after_lead_error_hook(result)
        ServiceResponse.error(message: result.message, reason: LEAD_FAILED)
      end

      def lead_service_class
        raise NoMethodError, 'Subclasses must implement the lead_service_class method'
      end

      def single_eligible_namespace_for_trial?
        return false unless namespaces_eligible_for_trial.any? # executes query and now relation is loaded

        namespaces_eligible_for_trial.count == 1
      end

      def namespaces_eligible_for_trial
        raise NoMethodError, 'Subclasses must implement the namespaces_eligible_for_trial method'
      end

      def trial_user_params
        attrs = {
          work_email: user.email,
          uid: user.id,
          setup_for_company: user.setup_for_company,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          provider: PROVIDER
        }

        lead_params.merge(attrs)
      end

      def apply_trial_flow
        trial_params[:namespace_id] = namespace.id

        result = apply_trial_service_class.new(
          uid: user.id,
          trial_user_information: trial_user_information_params
        ).execute

        if result.success?
          after_trial_success_hook
        else
          after_trial_error_hook(result)
        end
      end

      def after_trial_success_hook
        Gitlab::Tracking.event(self.class.name, 'create_trial', namespace: namespace, user: user)

        ServiceResponse.success(message: 'Trial applied', payload: { namespace: namespace })
      end

      def after_trial_error_hook(result)
        ServiceResponse.error(
          message: result.message,
          payload: { namespace_id: trial_params[:namespace_id] },
          reason: result.reason || TRIAL_FAILED
        )
      end

      def apply_trial_service_class
        raise NoMethodError, 'Subclasses must implement the apply_trial_service_class method'
      end

      def trial_flow
        # The value of 0 is the option in the select for creating a new group
        create_new_group_selected = trial_params[:namespace_id] == '0'

        if trial_params[:namespace_id].present? && !create_new_group_selected
          existing_namespace_flow
        elsif trial_params.key?(:new_group_name)
          create_group_flow
        else
          not_found
        end
      end

      def existing_namespace_flow
        @namespace = namespaces_eligible_for_trial.find_by_id(trial_params[:namespace_id])

        if namespace.present?
          apply_trial_flow
        else
          not_found
        end
      end

      def create_group_flow
        # Instance admins can disable user's ability to create top level groups.
        # See https://docs.gitlab.com/ee/administration/admin_area.html#prevent-a-user-from-creating-groups
        return not_found unless user.can_create_group?

        name = ActionController::Base.helpers.sanitize(trial_params[:new_group_name])
        path = Namespace.clean_path(name.parameterize)
        response = Groups::CreateService.new(user, name: name, path: path).execute
        @namespace = response[:group]

        if response.success?
          apply_trial_flow
        else
          ServiceResponse.error(
            message: namespace.errors.full_messages,
            payload: { namespace_id: trial_params[:namespace_id] },
            reason: NAMESPACE_CREATE_FAILED
          )
        end
      end

      def trial_user_information_params
        gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }
        namespace_params = {
          namespace: namespace.slice(:id, :name, :path, :kind, :trial_ends_on).merge(plan: namespace.actual_plan.name)
        }

        trial_params.except(:new_group_name).merge(gl_com_params).merge(namespace_params)
      end

      def not_found
        ServiceResponse.error(message: 'Not found', reason: NOT_FOUND)
      end
    end
  end
end
