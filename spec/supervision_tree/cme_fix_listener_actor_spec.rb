# frozen_string_literal: true
require 'spec_helper'

describe SupervisionTree::CmeFixListenerActor do
  let(:klass) { described_class }
  let(:instance) { klass.new(nil, 123) }

  before do
    allow_any_instance_of(klass).to receive(:start_requests!).and_return(nil)
    allow_any_instance_of(CmeFixListener::Client).to receive(:establish_session!).and_return(nil)
  end

  describe '#start_requests' do
    subject { instance.start_requests }

    it 'should call every 10 seconds' do
      allow_any_instance_of(klass).to receive(:every).with(10).and_yield
      expect_any_instance_of(klass).to receive(:async_make_request).and_return(nil)
      subject
    end
  end

  describe '#async_make_request' do
    subject { instance.async_make_request }

    context 'when inside operating window' do
      it 'should resume listener' do
        expect_any_instance_of(klass).to receive(:inside_operating_window?).and_return(true)
        expect_any_instance_of(klass).to receive(:resume_requests)
        expect_any_instance_of(klass).to receive(:log_resume_requests)
        expect_any_instance_of(klass).not_to receive(:pause_requests)
        expect(subject).to eq nil
      end
    end

    context 'when not inside operating window' do
      it 'should resume listener' do
        allow_any_instance_of(klass).to receive(:sleep_before_next_attempted_login).and_return(nil)
        expect_any_instance_of(klass).to receive(:inside_operating_window?).and_return(false)
        expect_any_instance_of(klass).to receive(:log_pause_requests)
        expect(CmeFixListener::HeartbeatManager).to receive(:add_maintenance_window_heartbeat_for_account).with(123)
        expect_any_instance_of(klass).not_to receive(:resume_requests)
        expect(subject).to eq nil
      end
    end
  end

  describe '#inside_operating_window?' do
    let(:current_time) { Time.now.utc }

    subject { instance.inside_operating_window? }
    before do
      expect_any_instance_of(klass).to receive(:current_time).and_return(current_time)
      expect(CmeFixListener::AvailabilityManager).to receive(:available?).with(current_time).and_return(return_value)
    end

    context 'when true' do
      let(:return_value) { true }
      it { expect(subject).to eq true }
    end

    context 'when false' do
      let(:return_value) { false }
      it { expect(subject).to eq false }
    end
  end

  describe '#resume_requests' do
    subject { instance.resume_requests }

    context 'when there is no account yet' do
      before { instance.account = nil }

      it 'should not call Client' do
        expect(CmeFixListener::Client).not_to receive(:new)
        expect_any_instance_of(CmeFixListener::Client).not_to receive(:establish_session!)
        subject
      end
    end

    context 'when there is an account' do
      before { instance.account = 'account' }

      it 'should call Client' do
        expect_any_instance_of(CmeFixListener::Client).to receive(:establish_session!)
        subject
      end
    end
  end

  describe '#log_resume_requests' do
    subject { instance.log_resume_requests }

    context 'when not paused' do
      before { instance.paused = false }

      it 'should not log or unpause' do
        expect(subject).to eq nil
        expect(instance.paused).to eq false
      end
    end

    context 'when paused' do
      before { instance.paused = true }

      it 'should log and unpause' do
        expect(subject).to eq nil
        expect(instance.paused).to eq false
      end
    end
  end

  describe '#pause_resume_requests' do
    subject { instance.log_pause_requests }

    context 'when paused' do
      before { instance.paused = true }

      it 'should not log or unpause' do
        expect(subject).to eq nil
        expect(instance.paused).to eq true
      end
    end

    context 'when not paused' do
      before { instance.paused = false }

      it 'should log and pause' do
        expect(subject).to eq nil
        expect(instance.paused).to eq true
      end
    end
  end
end
