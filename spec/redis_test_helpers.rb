# frozen_string_literal: true

module RedisTestHelpers
  def raise_redis_connection_error(method)
    expect(Resque.redis).to receive(method).and_raise(Redis::CannotConnectError)
  end

  def expect_errors_and_notify_honeybadger
    logger = double("logger object").as_null_object
    expect(Logging).to receive(:logger).and_return(logger)
    expect(Honeybadger).to receive(:notify)
    subject
  end
end
