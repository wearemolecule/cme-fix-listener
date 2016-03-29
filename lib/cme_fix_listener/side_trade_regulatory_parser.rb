# The SideTradeRegulatoryParser is responsible for the <TrdRegTS> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <TrdRegTS Typ="1" TS="2015-02-19T10:53:37-06:00"/>
#

module CmeFixListener
  # <TrdRegTS> Mappings from abbreviations to full names (with types)
  class SideTradeRegulatoryParser
    extend ParsingMethods

    MAPPINGS = [
      ['timestamp', 'TS'],
      ['timestampType', 'Typ', :to_i]
    ].freeze
  end
end
