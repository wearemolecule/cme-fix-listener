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
    exit
  rescue => e
    Honeybadger.notify(error_class: e, error_message: "Uncaught CME Exception: #{e.message}")
    retry
  end

  default_task :start
end

CmeThor.start
