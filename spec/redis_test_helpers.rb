# frozen_string_literal: true
module RedisTestHelpers
  def raise_redis_connection_error(method)
    expect(Resque.redis).to receive(method).and_raise(Redis::CannotConnectError)
  end

  def expect_errors_and_notify_honeybadger
    expect(Honeybadger).to receive(:notify)
    expect(subject[:errors].present?).to eq true
  end
end
