# frozen_string_literal: true

# The InstrumentParser is responsible for the <Instrmt> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <Instrmt PxQteCcy="USD" Exch="NYMEX" PutCall="0" UOM="MMBtu" Mult="10000" StrkPx="65.0" MatDt="2014-12-26"
# MMY="201501" SecTyp="OPT" CFI="OPAXPS" Src="H" ID="ON" Sym="ONF5 P65000"/>
#

module CmeFixListener
  # <Instrmt> Mappings from abbreviations to full names (with types)
  class InstrumentParser
    extend ParsingMethods

    MAPPINGS = [
      ["productSymbol", "Sym"],
      ["productCode", "ID"],
      ["productSourceCode", "Src"],
      ["cfiCode", "CFI"],
      ["securityType", "SecTyp"],
      ["indexName", "SubTyp"],
      ["contractPeriodCode", "MMY"],
      ["maturityDate", "MatDt"],
      ["nextCouponCode", "CpnPmt"],
      ["restructuringType", "RestrctTyp"],
      ["seniority", "Snrty"],
      ["strikePrice", "StrkPx", :to_f],
      ["priceMultiplier", "Mult", :to_f],
      ["unitOfMeasure", "UOM"],
      ["unitOfMeasureCurrency", "UOMCcy"],
      ["putCall", "PutCall", :to_i],
      ["couponRate", "CpnRt"],
      ["productExchange", "Exch"],
      ["nextCouponDate", "IntArcl"],
      ["priceQuoteCurrency", "PxQteCcy"]
    ].freeze
  end
end
