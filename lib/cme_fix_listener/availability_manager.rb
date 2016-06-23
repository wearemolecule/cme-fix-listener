# frozen_string_literal: true
module CmeFixListener
  # Used to determine if we can make requests to CME. Every day the CME API will go into a "maintaince mode".
  # At that point we should not make any requests to their API.
  class AvailabilityManager
    attr_accessor :current_time

    # Availability Times:
    # 5:00pm Sunday to 4:15pm Friday (Local Time)

    # Maintenance Window Times:
    # 04:15pm to 05:00pm -- Monday-Thursday

    def self.available?(current_time)
      @current_time = current_time
      (monday_through_thursday? && !in_maintenance_window?) ||
        sunday_after_five? ||
        friday_before_maintenance_window?
    end

    def self.end_of_maintenance_window_timestamp(current_time)
      @current_time = current_time
      @current_time = current_time.sunday unless monday_through_thursday?
      end_of_maintenance_window
    end

    def self.monday_through_thursday?
      @current_time.monday? || @current_time.tuesday? || @current_time.wednesday? ||
        @current_time.thursday?
    end

    def self.in_maintenance_window?
      @current_time > start_of_maintenance_window &&
        @current_time < end_of_maintenance_window
    end

    def self.sunday_after_five?
      return false unless @current_time.sunday?
      @current_time > end_of_maintenance_window
    end

    def self.friday_before_maintenance_window?
      return false unless @current_time.friday?
      @current_time < start_of_maintenance_window
    end

    def self.start_of_maintenance_window
      ActiveSupport::TimeZone.new(time_zone).local(@current_time.year,
                                                   @current_time.month,
                                                   @current_time.day, 16, 15, 00)
    end

    def self.end_of_maintenance_window
      ActiveSupport::TimeZone.new(time_zone).local(@current_time.year,
                                                   @current_time.month,
                                                   @current_time.day, 17, 00, 00)
    end

    def self.time_zone
      'Central Time (US & Canada)'
    end
  end
end
