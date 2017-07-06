# frozen_string_literal: true

module CmeFixListener
  # Handles any error while performing redis operations.
  class RedisManager
    extend ::ErrorNotifierMethods

    def self.catch_errors(action)
      yield if block_given?
    rescue StandardError => e
      notify_admins_of_error(e, error_message(e, action), error_context)
      { errors: e.message }
    end

    def self.error_message(e, action)
      "Unable to perform redis operation: #{action} with error: #{e.message}"
    end
  end
end
