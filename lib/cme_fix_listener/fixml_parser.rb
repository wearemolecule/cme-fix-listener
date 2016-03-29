module CmeFixListener
  # FIXML -> Hash Parser
  # Given a 5.0 SP2 FIXML message calling `parse_fixml` will create a Hash representation of the message.
  # The generated Hash will be eventually converted to JSON and sent to redis.
  # The JSON attempts to be JSON API compliant, please read the JSON API docs before making any changes to the
  # JSON representation.
  class FixmlParser
    include ParsingMethods

    attr_reader :message, :xml_doc, :trd_capt_rpt, :fixml
    attr_accessor :report_ack, :error_text

    def initialize(message)
      @message = message
      @xml_doc = Nokogiri::XML(message)
    end

    def parse_fixml
      return nil if trade_capture_reports.empty?
      deep_delete(transform_document)
    end

    def request_acknowledgement_text
      report_ack = @xml_doc.xpath('//TrdCaptRptReqAck')
      report_ack.empty? ? nil : report_ack.attr('Txt').to_s
    end

    def trade_capture_reports
      @trd_capt_rpts ||= @xml_doc.xpath('//TrdCaptRpt')
    end

    def transform_document
      transform_data.merge(transform_meta)
    end

    def transform_data
      { 'data' => trade_capture_reports.map { |trd_capt_rpt| transform_trade_capture_report(trd_capt_rpt) } }
    end

    def transform_meta
      { 'meta' => MetaParser.attributes_hash(@xml_doc.xpath('FIXML')) }
    end

    def transform_trade_capture_report(trd_capt_rpt)
      {
        'type' => 'TradeCaptureReport',
        'id' => TradeCaptureReportParser.parse_id(trd_capt_rpt)
      }.merge(attributes(trd_capt_rpt))
    end

    def attributes(trd_capt_rpt)
      {
        'attributes' => TradeCaptureReportParser.attributes_hash(trd_capt_rpt).
          merge(transform_instrmt(trd_capt_rpt.xpath('Instrmt'))).
          merge(transform_underlying(trd_capt_rpt.xpath('Undly'))).
          merge(transform_trade_legs(trd_capt_rpt.xpath('TrdLeg'))).
          merge(transform_report_side(trd_capt_rpt.xpath('RptSide')))
      }
    end

    def transform_instrmt(instrmt)
      { 'Instrument' => InstrumentParser.attributes_hash(instrmt) }
    end

    def transform_underlying(undlys)
      { 'UnderlyingInstrument' => undlys.map { |undly| UnderlyingInstrumentParser.attributes_hash(undly) } }
    end

    def transform_side_reg_trade_ts(reg_trd_tss)
      {
        'SideTradeRegulatoryTS' => reg_trd_tss.map do |reg_trd_ts|
          SideTradeRegulatoryParser.attributes_hash(reg_trd_ts)
        end
      }
    end

    def transform_trade_legs(trade_legs)
      {
        'TradeLegs' => trade_legs.map do |trade_leg|
          TradeLegParser.attributes_hash(trade_leg).
            merge(transform_leg_instrument(trade_leg.xpath('Leg'))).
            merge(transform_underlying_leg_instruments(trade_leg.xpath('Undlys')))
        end
      }
    end

    def transform_leg_instrument(leg)
      { 'Leg' => LegInstrumentParser.attributes_hash(leg) }
    end

    def transform_underlying_leg_instruments(undlys)
      {
        'UnderlyingLegInstruments' => undlys.map do |undly|
          UnderlyingLegInstrumentParser.attributes_hash(undly.xpath('Undly'))
        end
      }
    end

    def transform_report_side(rpt_side)
      {
        'ReportSide' => ReportSideParser.attributes_hash(rpt_side).
          merge(transform_parties(rpt_side.xpath('Pty'))).
          merge(transform_side_reg_trade_group(rpt_side.xpath('RegTrdID'))).
          merge(transform_side_reg_trade_ts(rpt_side.xpath('TrdRegTS')))
      }
    end

    def transform_parties(parties)
      {
        'Parties' => parties.map do |party|
          PartyParser.attributes_hash(party).merge(transform_party_sub_group(party))
        end
      }
    end

    def transform_party_sub_group(party)
      { 'PartySubGroup' => party.xpath('Sub').map { |sub_group| PartySubGroupParser.attributes_hash(sub_group) } }
    end

    def transform_side_reg_trade_group(reg_trd_ids)
      {
        'SideRegulatoryTradeIDGroup' => reg_trd_ids.map do |reg_trd_id|
          SideRegulatoryTradeGroupParser.attributes_hash(reg_trd_id)
        end
      }
    end
  end
end
