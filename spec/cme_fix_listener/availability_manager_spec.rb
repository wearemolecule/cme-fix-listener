# frozen_string_literal: true
require 'spec_helper'

describe CmeFixListener::AvailabilityManager do
  let(:klass) { described_class }
  let(:zone) { klass.time_zone }

  describe 'CME Availability' do
    subject { klass.available?(current_time) }

    context 'wednesday not between 4:15pm and 5:00pm local time' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o7, 16, 14, 0o0).in_time_zone(zone)
      end

      it { expect(subject).to eq true }
    end

    context 'wednesday between 4:15pm and 5:00pm local time' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o7, 16, 16, 0o0).in_time_zone(zone)
      end

      it { expect(subject).to eq false }
    end

    context 'saturday not between 4:15pm and 5:00pm local time' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o3, 16, 14, 0o0).in_time_zone(zone)
      end

      it { expect(subject).to eq false }
    end

    context 'sunday after 5:00pm local time' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o4, 17, 0o1, 0o0).in_time_zone(zone)
      end

      it { expect(subject).to eq true }
    end

    context 'sunday before 5:00pm local time' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o4, 16, 59, 0o0).in_time_zone(zone)
      end

      it { expect(subject).to eq false }
    end

    context 'friday before 4:15pm local time' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o2, 16, 14, 0o0).in_time_zone(zone)
      end

      it { expect(subject).to eq true }
    end

    context 'friday after 4:15pm local time' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o2, 16, 16, 0o0).in_time_zone(zone)
      end

      it { expect(subject).to eq false }
    end

    context 'saturday' do
      let(:current_time) do
        Time.new(2015, 0o1, 0o3).in_time_zone(zone)
      end

      it { expect(subject).to eq false }
    end
  end

  describe '.end_of_maintenance_window_timestamp' do
    subject { klass.end_of_maintenance_window_timestamp(current_time) }

    context 'weekday' do
      let(:current_time) do
        Time.new(2016, 4, 7).in_time_zone(zone)
      end

      it { expect(subject).to eq Time.new(2016, 4, 7, 17).in_time_zone(zone) }
    end

    context 'friday' do
      let(:current_time) do
        Time.new(2016, 4, 8).in_time_zone(zone)
      end

      it { expect(subject).to eq Time.new(2016, 4, 10, 17).in_time_zone(zone) }
    end

    context 'saturday' do
      let(:current_time) do
        Time.new(2016, 4, 9).in_time_zone(zone)
      end

      it { expect(subject).to eq Time.new(2016, 4, 10, 17).in_time_zone(zone) }
    end

    context 'sunday before 5' do
      let(:current_time) do
        Time.new(2016, 4, 10, 12).in_time_zone(zone)
      end

      it { expect(subject).to eq Time.new(2016, 4, 10, 17).in_time_zone(zone) }
    end
  end
end
