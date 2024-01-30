# frozen_string_literal: true

# Duo Pro Bulk User Assignment
# 1. Set the `add_on_purchase` variable to point to your AddOnPurchase record
# add_on_purchase = GitlabSubscriptions::AddOnPurchase.find_by(add_on: GitlabSubscriptions::AddOn.code_suggestions.last)
# 2. Set the `usernames` variable to point to an array of usernames:
#    usernames = ["user1", "user2", "user3", "user4", "user5"]
#    If reading from a CSV file
#    usernames =  CSV.read(FILE_PATH, headers: true).pluck('username')
# 3. Execute the bulk assignment:
#    DuoPro::BulkUserAssignment.new(usernames, add_on_purchase).execute

# Error Messages:
# - `User is not found`
# - `ERROR_NO_SEATS_AVAILABLE`: No more seats are available.
# - `ERROR_INVALID_USER_MEMBERSHIP`: User is not eligible for assignment due to being inactive, a bot, or a ghost.

module DuoPro
  class BulkUserAssignment
    attr_reader :usernames, :add_on_purchase, :successful_assignments, :failed_assignments

    def initialize(usernames, add_on_purchase)
      @usernames = usernames
      @add_on_purchase = add_on_purchase
      @successful_assignments = []
      @failed_assignments = []
    end

    def execute
      return 'AddOn not purchased' unless add_on_purchase

      process_users(usernames)

      { successful_assignments: successful_assignments, failed_assignments: failed_assignments }
    end

    private

    def process_users(usernames)
      usernames.each do |username|
        user_to_be_assigned = User.find_by_username(username)

        unless user_to_be_assigned
          log_failed_assignment("User is not found: #{username}")
          next
        end

        result = assign(user_to_be_assigned)

        if result.errors.include?("NO_SEATS_AVAILABLE")
          log_no_seats_available(result, username)
          break
        end

        log_result(result, username)
      end
    end

    def assign(user)
      ::GitlabSubscriptions::UserAddOnAssignments::SelfManaged::CreateService.new(
        add_on_purchase: add_on_purchase,
        user: user
      ).execute
    end

    def log_no_seats_available(result, username)
      log_failed_assignment("Failed to assign seat to user: #{username}, Errors: #{result.errors}")
      log_failed_assignment("##No seats are left; users starting from @#{username} onwards were not assigned.##")
    end

    def log_successful_assignment(username)
      successful_assignments << "User assigned: #{username}"
    end

    def log_failed_assignment(message)
      failed_assignments << message
    end

    def log_result(result, username)
      if result.errors.empty?
        log_successful_assignment(username)
      else
        log_failed_assignment("Failed to assign seat to user: #{username}, Errors: #{result.errors}")
      end
    end
  end
end
