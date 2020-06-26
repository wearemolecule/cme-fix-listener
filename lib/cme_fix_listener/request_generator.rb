# frozen_string_literal: true

require "active_support/testing/time_helpers"
module CmeFixListener
  # Builds a valid trade capture report request xml message required by CME.
  class RequestGenerator
    include Nokogiri

    attr_accessor :account, :request_id, :username, :firm_sid, :party_role

    def initialize(account)
      @account = account
      @request_id = account["cmeRequestID"]
      @username = account["cmeUsername"]
      @firm_sid = account["cmeFirmSid"]
      @party_role = account["cmePartyRole"]
    end

    def build_xml(request_type)
      params = initial_history(request_type)
      Nokogiri::XML::Builder.new do |xml|
        xml.FIXML(fixml_attrs) do
          xml.TrdCaptRptReq(trd_cpt_rpt_request_attrs(request_type).merge(params)) do
            xml.Hdr(header_attrs)
            xml.Pty(party_attrs)
          end
        end
      end.to_xml
    end

    protected

    def initial_history(request_type)
      return {} if request_type != "1"
      start_time = Time.now - 1.hour
      {
        "StartTm" => start_time.to_s(:iso8601)
      }
    end

    def generator_type
      "REGULAR"
    end

    def fixml_attrs
      {
        v: "5.0 SP2",
        s: "20090815",
        xv: "109",
        cv: "CME.0001"
      }
    end

    def trd_cpt_rpt_request_attrs(request_type)
      {
        ReqID: [ENV.fetch("NAMESPACE", "DEVELOPMENT"), @account["id"], generator_type, @account["cmeRequestID"]].join("-"),
        ReqTyp: request_type,
        SubReqTyp: "1",
        MLegRptTyp: "3"
      }
    end

    def header_attrs
      {
        SID: @firm_sid,
        TID: "CME",
        SSub: @username,
        TSub: "STP"
      }
    end

    def party_attrs
      {
        ID: @firm_sid,
        R: @party_role
      }
    end
  end
end
