# frozen_string_literal: true

# The TradeCaptureReportParser is responsible for the <TrdCaptRpt> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <TrdCaptRpt LastUpdateTm="2015-02-19T10:55:22.575-06:00" TxnTm="2015-02-19T10:55:22-06:00" MLegRptTyp="1"
# BizDt="2015-02-19" TrdDt="2015-02-19" LastPx="3.450" LastQty="2" VenuTyp="E" PxTyp="2"
# ExecID="47949520150219105337TN0007733" MtchID="14B996E6EF2TP0102D77FC3A" TrdTyp="0" ReqID="your-company-name"
# TrdRptStat="0" RptTyp="101" TransTyp="2" TrdID2="14B996E6EF2TP0102D77FC3C" TrdID="123503"
# RptID="14B996E6EF2TP0102D77FC3C1105522575">
#

module CmeFixListener
  # <TrdCaptRpt> Mappings from abbreviations to full names (with types)
  class TradeCaptureReportParser
    extend ParsingMethods

    MAPPINGS = [
      ["messageID", "RptID"],
      ["tradeID", "TrdID"],
      ["secondaryTradeID", "TrdID2"],
      ["packageID", "PackageID"],
      ["transactionType", "TransTyp", :to_i],
      ["tradeReportType", "RptTyp", :to_i],
      ["tradeStatus", "TrdRptStat", :to_i],
      ["requestID", "ReqID"],
      ["tradeType", "TrdTyp", :to_i],
      ["tradeSubType", "TrdSubTyp", :to_i],
      ["offsetInstruction", "OfstInst", :to_i],
      ["tradeMatchID", "MtchID"],
      ["executionID", "ExecID"],
      ["secondaryExecutionID", "ExecID2"],
      ["blockID", "BlckID"],
      ["priceType", "PxTyp", :to_i],
      ["venueType", "VenuTyp"],
      ["quantityType", "QtyTyp", :to_i],
      ["tradeQuantity", "LastQty", :to_f],
      ["tradePrice", "LastPx", :to_f],
      ["tradeDate", "TrdDt"],
      ["clearDate", "BizDt"],
      ["averagePrice", "AvgPx", :to_f],
      ["multiLegReportingType", "MLegRptTyp"],
      ["transactionTime", "TxnTm"],
      ["lastUpdateTime", "LastUpdateTm"],
      ["tradePriceNegotiationMethod", "PxNeg", :to_i],
      ["differentialPrice", "DiffPx", :to_f],
      ["differentialPriceType", "DiffPxtyp", :to_i],
      ["originalTimeUnit", "OrigTmUnit"]
    ].freeze

    def self.parse_id(trd_cpt_rpt)
      xpath_value(trd_cpt_rpt, "@RptID", :to_s) + xpath_value(trd_cpt_rpt, "@TrdID2", :to_s)
    end
  end
end
