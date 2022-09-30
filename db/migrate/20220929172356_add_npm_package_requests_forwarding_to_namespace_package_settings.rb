# frozen_string_literal: true

class AddNpmPackageRequestsForwardingToNamespacePackageSettings < Gitlab::Database::Migration[2.0]
  def change
    # adds columns to match the format used in
    # Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings#add_cascading_namespace_setting
    add_column(:namespace_package_settings,
      :npm_package_requests_forwarding,
      :boolean,
      null: true,
      default: nil
    )

    add_column(:namespace_package_settings,
      :lock_npm_package_requests_forwarding,
      :boolean,
      default: false,
      null: false
    )

    add_column(:application_settings,
      :lock_npm_package_requests_forwarding,
      :boolean,
      default: false,
      null: false
    )
  end
end
