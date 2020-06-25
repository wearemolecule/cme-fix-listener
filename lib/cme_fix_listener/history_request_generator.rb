# frozen_string_literal: true

module CmeFixListener
  # Builds a valid trade capture report HISTORY request xml message required by CME.
  class HistoryRequestGenerator < RequestGenerator
    attr_accessor :start_time, :end_time

    def initialize(account, start_time, end_time)
      super(account)
      @start_time = start_time
      @end_time = end_time
    end

    def build_xml(request_type)
      return if @start_time.blank? || @end_time.blank?
      Nokogiri::XML::Builder.new do |xml|
        xml.FIXML(fixml_attrs) do
          xml.TrdCaptRptReq(trd_cpt_rpt_request_attrs(request_type).merge(history_params)) do
            xml.Hdr(header_attrs)
            xml.Pty(party_attrs)
          end
        end
      end.to_xml
    end

    def history_params
      {
        "SubReqTyp" => "0",
        "StartTm" => start_time,
        "EndTm" => end_time
      }
    end

    def generator_type
      "HISTORY"
    end
  end
end
