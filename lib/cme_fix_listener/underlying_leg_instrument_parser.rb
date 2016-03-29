# The UnderlyingLegInstrumentParser is responsible for the <Undly> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <Undlys>
#   <Undly Exch="NYMEX" MMY="201508" SecTyp="FUT" Src="H" ID="CL"/>
# </Undlys>
#

module CmeFixListener
  # <Undly> Mappings from abbreviations to full names (with types)
  class UnderlyingLegInstrumentParser
    extend ParsingMethods

    MAPPINGS = [
      ['legUnderlyingProductCode', 'ID'],
      ['legUnderlyingProductCodeSource', 'Src'],
      ['legUnderlyingSecurityType', 'SecTyp'],
      ['legUnderlyingMaturity', 'MMY'],
      ['legUnderlyingProductExchange', 'Exch']
    ].freeze
  end
end
