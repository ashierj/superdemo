# frozen_string_literal: true

module AuditEvents
  module ExternallyStreamable
    extend ActiveSupport::Concern

    included do
      before_validation :assign_default_name

      enum type: {
        http: 0,
        gcp: 1,
        aws: 2
      }

      validates :name, length: { maximum: 72 }
      validates :type, presence: true

      validates :config, presence: true, json_schema: { filename: 'external_streaming_destination_config' }
      validates :secret_token, presence: true

      attr_encrypted :secret_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm',
        encode: false,
        encode_iv: false

      private

      def assign_default_name
        self.name ||= "Destination_#{SecureRandom.uuid}"
      end
    end
  end
end
