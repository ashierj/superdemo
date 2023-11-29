# frozen_string_literal: true

class FixBrokenUserAchievementsRevoked < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '16.7'

  def up
    update_column_in_batches(:user_achievements, :revoked_by_user_id, Users::Internal.ghost.id) do |table, query|
      query.where(table[:revoked_at].not_eq(nil)).where(table[:revoked_by_user_id].eq(nil))
    end
  end

  def down
    # noop -- this is a data migration and can't be reversed
  end
end
