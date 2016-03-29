# The LegInstrumentParser is responsible for the <Leg> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <Leg PutCall="0" Side="1" Exch="NYMEX" Mult="1000" Strk="40.0" Mat="2015-06-17" MMY="20150700" SecTyp="OPT"
# CFI="OPAEPS" Src="H" ID="LO" Sym="LON5 P4000"/>
#

module CmeFixListener
  # <Leg> Mappings from abbreviations to full names (with types)
  class LegInstrumentParser
    extend ParsingMethods

    MAPPINGS = [
      ['legSymbol', 'Sym'],
      ['legProductCode', 'ID'],
      ['legProductIDSource', 'Src'],
      ['legCFI', 'CFI'],
      ['legSecurityType', 'SecTyp'],
      ['legMaturity', 'MMY'],
      ['legMaturityDate', 'Mat'],
      ['legStrikePrice', 'Strk', :to_f],
      ['legContractMultiplier', 'Mult', :to_f],
      ['legProductExchange', 'Exch'],
      ['legBuySellCode', 'Side'],
      ['legPutCall', 'PutCall', :to_i]
    ].freeze
  end
end
