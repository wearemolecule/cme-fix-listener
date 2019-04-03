# frozen_string_literal: true

# Helper methods used to notify us of errors
module ErrorNotifierMethods
  include Logging

  def notify_admins_of_error(error, error_message, error_context)
    Logging.logger.error { error }
    Logging.logger.error { [error_message, error_context] }
    Honeybadger.notify(error, error_message: error_message, context: error_context)
  end

  def not_entitled?(error_txt)
    (error_txt =~ /not entitled/).present?
  end

  def not_entitled_error_message
    "#{@account['name']} is not entitled (Usually a URL Issue)"
  end

  def does_not_belong_to?(error_txt)
    (error_txt =~ /not belong to/).present?
  end

  def does_not_belong_to_error_message
    "Creds do not belong to #{@account['name']} (Usually a Firm SID Issue)"
  end

  def authentication_failed?(error_txt)
    (error_txt =~ /authentication failed/).present?
  end

  def authentication_failed_error_message
    "Invalid Credentials for Account"
  end

  def query_error?(error_txt)
    (error_txt =~ /query error/).present?
  end

  def query_error_message
    "Request ID or Party Role most likely not set correctly"
  end
end
