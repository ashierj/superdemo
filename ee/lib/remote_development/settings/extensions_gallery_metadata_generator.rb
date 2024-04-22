# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class ExtensionsGalleryMetadataGenerator
      include Messages

      # NOTE: These `disabled_reason` enumeration values are also referenced/consumed in
      #       the "gitlab-web-ide" and "gitlab-web-ide-vscode-fork" projects
      #       (https://gitlab.com/gitlab-org/gitlab-web-ide & https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork),
      #       so we must ensure that any changes made here are also reflected in those projects.
      DISABLED_REASONS =
        %i[
          no_user
          no_flag
          instance_disabled
          opt_in_unset
          opt_in_disabled
        ].to_h { |reason| [reason, reason] }.freeze

      # @param [Hash] value
      # @return [Hash]
      def self.generate(value)
        value => { options: Hash => options }
        options_with_defaults = { user: nil, vscode_extensions_marketplace_feature_flag_enabled: nil }.merge(options)
        options_with_defaults => {
          user: ::User | NilClass => user,
          vscode_extensions_marketplace_feature_flag_enabled: TrueClass | FalseClass | NilClass =>
            extensions_marketplace_feature_flag_enabled
        }

        extensions_gallery_metadata = generate_settings(
          user: user,
          flag_enabled: extensions_marketplace_feature_flag_enabled
        )

        value[:settings][:vscode_extensions_gallery_metadata] = extensions_gallery_metadata
        value
      end

      # @param [User, nil] user
      # @param [Boolean, nil] flag_enabled
      # @return [Hash]
      def self.generate_settings(user:, flag_enabled:)
        return { enabled: false, disabled_reason: DISABLED_REASONS.fetch(:no_user) } unless user
        return { enabled: false, disabled_reason: DISABLED_REASONS.fetch(:no_flag) } if flag_enabled.nil?
        return { enabled: false, disabled_reason: DISABLED_REASONS.fetch(:instance_disabled) } unless flag_enabled

        # noinspection RubyNilAnalysis -- RubyMine doesn't realize user can't be nil because of guard clause above
        opt_in_status = user.extensions_marketplace_opt_in_status.to_sym

        return { enabled: true } if opt_in_status == :enabled
        return { enabled: false, disabled_reason: DISABLED_REASONS.fetch(:opt_in_unset) } if opt_in_status == :unset

        if opt_in_status == :disabled
          return { enabled: false, disabled_reason: DISABLED_REASONS.fetch(:opt_in_disabled) }
        end

        # This is an internal bug due to an enumeration mismatch/inconsistency with the model, so lets throw an
        # exception up the stack and let it be returned as a 500 - don't try to handle it via the ROP chain
        raise "Invalid user.extensions_marketplace_opt_in_status: '#{opt_in_status}'. " \
          "Supported statuses are: #{Enums::WebIde::ExtensionsMarketplaceOptInStatus.statuses.keys}." # rubocop:disable Layout/LineEndStringConcatenationIndentation -- This is already changed in the next version of gitlab-styles
      end
    end
  end
end
