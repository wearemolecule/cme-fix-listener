# frozen_string_literal: true

# The TradeLegParser is responsible for the <TrdLeg> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <TrdLeg LastPx="4.300" RefID="101066" LegNo="1" RptID="14DDEDEFAEF0004D4F30" Qty="70">
#

module CmeFixListener
  # <TrdLeg> Mappings from abbreviations to full names (with types)
  class TradeLegParser
    extend ParsingMethods

    MAPPINGS = [
      ["legQuantity", "Qty", :to_f],
      ["legReportID", "RptID"],
      ["legNumber", "LegNo", :to_i],
      ["legReferenceID", "RefID"],
      ["legLastPrice", "LastPx", :to_f],
      ["legOriginalTimeUnit", "OrigTmUnit"]
    ].freeze
  end
end
