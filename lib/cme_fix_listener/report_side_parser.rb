# The ReportSideParser is responsible for the <RptSide> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <RptSide CustCpcty="4" InptSrc="GLBX" ClOrdID="6A8GE" Side="1">
#

module CmeFixListener
  # <RptSide> Mappings from abbreviations to full names (with types)
  class ReportSideParser
    extend ParsingMethods

    MAPPINGS = [
      ['buySellCode', 'Side'],
      ['clientOrderID', 'ClOrdID'],
      ['sideCurrency', 'Ccy'],
      ['inputSource', 'InptSrc'],
      ['cti', 'CustCpcty', :to_i],
      ['allocationIndicator', 'AllocInd', :to_i],
      ['averagePriceIndicator', 'AvgPxInd', :to_i],
      ['strategyLinkID', 'StrategyLinkID'],
      ['secondaryAllocationGroupID', 'GrpID2']
    ].freeze
  end
end
