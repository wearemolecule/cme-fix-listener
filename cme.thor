# frozen_string_literal: true

# !/usr/bin/env ruby

require_relative "config/application.rb"

# Thor is used to start CME trade capture.
class CmeThor < Thor
  def initialize(*_args)
    super
    app_init
  end

  desc "start", "Start trade capture"
  def start
    work
  rescue SignalException => e
    # just gracefully exit
    puts "received signal #{e}"
    exit
  rescue => e
    Honeybadger.notify(error_class: e, error_message: "Uncaught CME Exception: #{e.message}")
    work
  end

  private

  def work
    Worker::Master.new.work!
  end

  default_task :start
end

CmeThor.start
