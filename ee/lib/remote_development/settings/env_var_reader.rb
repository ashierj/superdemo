# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class EnvVarReader
      include Messages

      REQUIRED_ENV_VAR_PREFIX = "GITLAB_REMOTE_DEVELOPMENT"

      # @param [Hash] value
      # @return [Result]
      def self.read(value)
        err_result = nil
        value[:settings].each_key do |setting_name|
          env_var_name = "#{REQUIRED_ENV_VAR_PREFIX}_#{setting_name.to_s.upcase}"
          env_var_value_string = ENV[env_var_name]

          # If there is no matching ENV var, break the loop and go to the next setting
          next unless env_var_value_string

          begin
            env_var_value = cast_value(
              env_var_name: env_var_name,
              env_var_value_string: env_var_value_string,
              setting_type: value[:setting_types][setting_name]
            )
          rescue RuntimeError => e
            # err_result will be set to a non-nil Result.err if casting fails
            err_result = Result.err(SettingsEnvironmentVariableReadFailed.new(details: e.message))
          end

          # ENV var matches an existing setting and is of the correct type, use its value to override the default value
          value[:settings][setting_name] = env_var_value
        end

        return err_result if err_result

        Result.ok(value)
      end

      # @param [String] env_var_name
      # @param [Integer,String] env_var_value_string
      # @param [Class] setting_type
      # @return [Object]
      # @raise [RuntimeError]
      def self.cast_value(env_var_name:, env_var_value_string:, setting_type:)
        if setting_type == String
          env_var_value_string
        elsif setting_type == Integer
          # NOTE: The following line works because String#to_i does not raise exceptions for non-integer values
          unless env_var_value_string.to_i.to_s == env_var_value_string
            raise "ENV var '#{env_var_name}' value could not be cast to #{setting_type} type."
          end

          env_var_value_string.to_i
        else
          raise "Unsupported Remote Development setting type: #{setting_type}"
        end
      end
    end
  end
end
