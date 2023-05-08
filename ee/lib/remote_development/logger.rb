# frozen_string_literal: true

module RemoteDevelopment
  class Logger < ::Gitlab::JsonLogger
    def self.file_name_noext
      'remote_development'
    end
  end
end
