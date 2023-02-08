# frozen_string_literal: true

class BackfillCiBuildNeedsForBigIntConversion < Gitlab::Database::Migration[2.1]
  TABLE = :ci_build_needs
  COLUMNS = %i[id]

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
