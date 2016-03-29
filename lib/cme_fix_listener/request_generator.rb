module CmeFixListener
  # Builds a valid trade capture report request xml message required by CME.
  class RequestGenerator
    include Nokogiri

    attr_accessor :account, :request_id, :username, :firm_sid, :party_role

    def initialize(account)
      @account = account
      @request_id = account['cmeRequestId']
      @username = account['cmeUsername']
      @firm_sid = account['cmeFirmSid']
      @party_role = account['cmePartyRole']
    end

    def build_xml(request_type)
      Nokogiri::XML::Builder.new do |xml|
        xml.FIXML(fixml_attrs) do
          xml.TrdCaptRptReq(trd_cpt_rpt_request_attrs(request_type)) do
            xml.Hdr(header_attrs)
            xml.Pty(party_attrs)
          end
        end
      end.to_xml
    end

    private

    def fixml_attrs
      {
        v: '5.0 SP2',
        s: '20090815',
        xv: '109',
        cv: 'CME.0001'
      }
    end

    def trd_cpt_rpt_request_attrs(request_type)
      {
        ReqID: @request_id,
        ReqTyp: request_type,
        SubReqTyp: '1',
        MLegRptTyp: '3'
      }
    end

    def header_attrs
      {
        SID: @firm_sid,
        TID: 'CME',
        SSub: @username,
        TSub: 'STP'
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
