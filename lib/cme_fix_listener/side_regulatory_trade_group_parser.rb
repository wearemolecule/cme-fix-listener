# frozen_string_literal: true

# The SideRegulatoryTradeGroupParser is responsible for the <RegTrdID> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <RegTrdID Typ="0" Evnt="2" Src="1010000023" ID="FECC14B996E6EF2TP0102D77FC3C"/>
#

module CmeFixListener
  # <RegTrdID> Mappings from abbreviations to full names (with types)
  class SideRegulatoryTradeGroupParser
    extend ParsingMethods

    MAPPINGS = [
      ["sideRegulatoryTradeID", "ID"],
      ["sideRegulatoryTradeSource", "Src"],
      ["sideRegulatoryTradeEvent", "Evnt", :to_i],
      ["sideRegulatoryTradeType", "Typ", :to_i],
      ["sideRegulatoryLegReferenceID", "LegRefID"],
      ["sideRegulatoryTradeIDScope", "Scope", :to_i]
    ].freeze
  end
end
