#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "config/application.rb"

# Thor is used to start CME trade capture.
class CmeThor < Thor
  def initialize(*_args)
    super
    app_init
  end

  desc "start", "Start trade capture"
  def start
    Worker::Master.new.work!
  rescue SignalException => e
    # just gracefully exit
    puts "received signal #{e}"
    kill_all_threads
    exit
  rescue => e
    Logging.logger.error { "Uncaught CME Exception: #{e.message}" }
    Honeybadger.notify(error_class: e, error_message: "Uncaught CME Exception: #{e.message}", backtrace: e.backtrace)
    kill_all_threads
    retry
  end
  default_task :start

  private

  def kill_all_threads
    Thread.list.each do |thread|
      thread.exit unless thread == Thread.current
    end
  end
end

CmeThor.start
