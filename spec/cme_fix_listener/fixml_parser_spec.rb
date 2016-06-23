# frozen_string_literal: true
require 'spec_helper'

describe CmeFixListener::FixmlParser do
  let(:klass) { described_class }
  let(:instance) { klass.new(xml_message) }

  let(:xml_filename) { '' }
  let(:json_filename) { '' }
  let(:xml_file_path) { File.join("spec/datafiles/#{xml_filename}") }
  let(:json_file_path) { File.join("spec/datafiles/#{json_filename}") }
  let(:xml_file) { File.open(xml_file_path) }
  let(:json_file) { File.open(json_file_path) }

  let(:xml_message) { xml_file.read }
  let(:json_message) { json_file.read }

  describe '#parse_fixml' do
    subject { instance.parse_fixml }

    context 'when the message is a heartbeat (no TrdCaptRpts)' do
      let(:xml_filename) { 'heartbeat.xml' }

      it { expect(subject.blank?).to eq true }
    end

    context 'when the message contains a single TrdCaptRpt' do
      let(:xml_filename) { 'single_trade_capture_report.xml' }
      let(:json_filename) { 'single_trade_capture_report.json' }

      it { expect_non_empty_json_response }
    end

    context 'when the message contains a many TrdCaptRpt' do
      let(:xml_filename) { 'multiple_trade_capture_reports.xml' }
      let(:json_filename) { 'multiple_trade_capture_reports.json' }

      it { expect_non_empty_json_response }
    end

    context 'when the message contains a TrdLegs within a TrdCaptRpt' do
      let(:xml_filename) { 'trade_legs_trade_capture_report.xml' }
      let(:json_filename) { 'trade_legs_trade_capture_report.json' }

      it { expect_non_empty_json_response }
    end
  end

  describe '#request_acknowledgement_text' do
    subject { instance.request_acknowledgement_text }

    context 'when there is a a TrdCaptRptAck' do
      let(:xml_filename) { 'trade_capture_report_ack.xml' }

      it { expect(subject.present?).to eq true }
    end

    context 'when there is not a TrdCaptRptAck' do
      let(:xml_filename) { 'single_trade_capture_report.xml' }

      it { expect(subject.present?).to eq false }
    end
  end

  def expect_non_empty_json_response
    expect(subject).to eq JSON.parse(json_message)
    expect(subject.to_json).not_to be_empty
  end
end
