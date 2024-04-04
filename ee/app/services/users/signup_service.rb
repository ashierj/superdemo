# frozen_string_literal: true

module Users
  class SignupService < BaseService
    def initialize(current_user, params = {})
      @user = current_user
      @params = params.dup
    end

    def execute
      assign_attributes
      inject_validators

      if @user.save
        ServiceResponse.success(payload: payload)
      else
        user_errors = @user.errors.full_messages.join('. ')

        msg = <<~MSG.squish
          #{self.class.name}: Could not save user with errors: #{user_errors} and
          onboarding_status: #{@user.onboarding_status}
        MSG

        log_error(msg)

        ServiceResponse.error(message: user_errors, payload: payload)
      end
    end

    private

    def payload
      { user: @user.reset }
    end

    def assign_attributes
      @user.assign_attributes(params) unless params.empty?
    end

    def inject_validators
      class << @user
        validates :role, presence: true
        validates :setup_for_company, inclusion: { in: [true, false], message: :blank }
      end
    end
  end
end
