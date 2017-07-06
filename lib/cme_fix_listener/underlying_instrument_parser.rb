# frozen_string_literal: true

# The UnderlyingInstrumentParser is responsible for the <Undly> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <Undly Exch="NYMEX" MMY="201501" SecTyp="FUT" Src="H" ID="NG"/>
#

module CmeFixListener
  # <Undly> Mappings from abbreviations to full names (with types)
  class UnderlyingInstrumentParser
    extend ParsingMethods

    MAPPINGS = [
      ["underlyingProductCode", "ID"],
      ["underlyingProductCodeSource", "Src"],
      ["underlyingSecurityType", "SecTyp"],
      ["underlyingMaturity", "MMY"],
      ["underlyingProductExchange", "Exch"]
    ].freeze
  end
end
