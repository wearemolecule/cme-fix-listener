#!/usr/bin/env ruby

require_relative 'config/application.rb'

# In this context thor is used to start the program. The command ./cme.thor will call the default start_supervising method (after initialization).
class CmeThor < Thor
  def initialize(*_args)
    super
    app_init
  end

  desc 'start', 'Start celluloid'
  def start_supervising
    loop do
      group = SupervisionTree::MasterSupervisor.start_working!
      sleep 30 while group.alive?
      puts "Celluloid::Supervision::Container #{self} crashed. Restarting..."
    end
  end

  default_task :start_supervising
end

CmeThor.start
