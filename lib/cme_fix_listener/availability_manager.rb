# frozen_string_literal: true

module CmeFixListener
  # Used to determine if we can make requests to CME. Every day the CME API will go into a "maintaince mode".
  # At that point we should not make any requests to their API.
  class AvailabilityManager
    TIMEZONE = "Central Time (US & Canada)"
    attr_accessor :current_time

    # Availability Times:
    # 5:00pm Sunday to 4:15pm Friday (Local Time)

    # Maintenance Window Times:
    # 04:15pm to 05:00pm -- Monday-Thursday

    def initialize(current_time)
      @current_time = current_time
    end

    def available?
      (monday_through_thursday? && !in_maintenance_window?) ||
        sunday_after_five? ||
        friday_before_maintenance_window?
    end

    def end_of_maintenance_window_timestamp
      if monday_through_thursday?
        end_of_maintenance_window(current_time)
      else
        end_of_maintenance_window(current_time.sunday)
      end
    end

    private

    def monday_through_thursday?
      current_time.monday? || current_time.tuesday? || current_time.wednesday? ||
        current_time.thursday?
    end

    def in_maintenance_window?
      current_time > start_of_maintenance_window(current_time) &&
        current_time < end_of_maintenance_window(current_time)
    end

    def sunday_after_five?
      return false unless current_time.sunday?
      current_time > end_of_maintenance_window(current_time)
    end

    def friday_before_maintenance_window?
      return false unless current_time.friday?
      current_time < start_of_maintenance_window(current_time)
    end

    def start_of_maintenance_window(given_time)
      ActiveSupport::TimeZone.new(TIMEZONE).local(given_time.year,
                                                  given_time.month,
                                                  given_time.day, 16, 15, 0o0)
    end

    def end_of_maintenance_window(given_time)
      ActiveSupport::TimeZone.new(TIMEZONE).local(given_time.year,
                                                  given_time.month,
                                                  given_time.day, 17, 0o0, 0o0)
    end
  end
end
