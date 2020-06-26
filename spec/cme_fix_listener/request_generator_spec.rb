# frozen_string_literal: true

require "spec_helper"

describe CmeFixListener::RequestGenerator do
  include ActiveSupport::Testing::TimeHelpers

  let(:klass) { described_class }
  let(:instance) { klass.new(account) }
  let(:content_type) { "text/xml" }

  let(:account) do
    {
      "id" => "400",
      "cmeRequestID" => "COMPANY_NAME",
      "cmeUsername" => "USERNAME_SPEC",
      "cmeFirmSid" => "COMPANY_SPEC",
      "cmePartyRole" => "7"
    }
  end

  let(:file) { File.open(file_path) }
  let(:file_path) { File.join("spec/datafiles/#{file_name}") }

  describe "#build_xml" do
    let(:message_spec) { file.read }
    let(:message_spec_xml) { (Nokogiri::XML message_spec).to_xml }

    context "initial subscription" do
      let(:file_name) { "trading_firm_initial_subscription.xml" }
      let(:some_point_in_time) { Time.parse("2013-10-22T12:00:00-05:00") }
      it "builds xml for initial request with hour of history" do
        travel_to(some_point_in_time) do
          expect(instance.build_xml("1")).to eq message_spec_xml
        end
      end
    end

    context "continued subscription" do
      let(:file_name) { "trading_firm_continued_subscription.xml" }
      it { expect(instance.build_xml("3")).to eq message_spec_xml }
    end
  end
end
