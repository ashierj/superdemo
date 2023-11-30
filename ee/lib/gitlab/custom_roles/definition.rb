# frozen_string_literal: true

module Gitlab
  module CustomRoles
    class Definition
      include ::Gitlab::CustomRoles::Shared

      class << self
        attr_accessor :definitions

        def all
          load_abilities! if @definitions.nil?

          @definitions
        end

        def load_abilities!
          @definitions = {}

          Dir.glob(path).each do |file|
            definition = load_from_file(file)
            name = definition[:name].to_sym

            @definitions[name] = definition
          end
        end

        private

        def path
          Rails.root.join("ee/config/custom_abilities/*.yml")
        end

        def load_from_file(path)
          definition = File.read(path)
          definition = YAML.safe_load(definition)
          definition.deep_symbolize_keys
        end
      end
    end
  end
end
