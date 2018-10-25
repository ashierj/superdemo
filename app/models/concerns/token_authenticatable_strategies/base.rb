# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Base
    def initialize(klass, token_field, options)
      @klass = klass
      @token_field = token_field
      @options = options
    end

    def find_token_authenticatable(instance, unscoped = false)
      raise NotImplementedError
    end

    def get_token(instance)
      raise NotImplementedError
    end

    def set_token(instance)
      raise NotImplementedError
    end

    def ensure_token(instance)
      write_new_token(instance) unless token_set?(instance)
    end

    # Returns a token, but only saves when the database is in read & write mode
    def ensure_token!(instance)
      reset_token!(instance) unless token_set?(instance)
      get_token(instance)
    end

    # Resets the token, but only saves when the database is in read & write mode
    def reset_token!(instance)
      write_new_token(instance)
      instance.save! if Gitlab::Database.read_write?
    end

    protected

    def write_new_token(instance)
      new_token = generate_available_token
      set_token(instance, new_token)
    end

    def generate_available_token
      loop do
        token = generate_token
        break token unless find_token_authenticatable(token, true)
      end
    end

    def generate_token
      @options[:token_generator] ? @options[:token_generator].call : Devise.friendly_token
    end

    def relation(unscoped)
      unscoped ? @klass.unscoped : @klass
    end

    def token_set?(instance)
      raise NotImplementedError
    end

    def token_field_name
      @token_field
    end
  end
end
