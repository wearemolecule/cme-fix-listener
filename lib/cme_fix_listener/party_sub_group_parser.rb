# The PartySubGroupParser is responsible for the <Sub> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <Sub Typ="26" ID="1"/>
#

module CmeFixListener
  # <Sub> Mappings from abbreviations to full names (with types)
  class PartySubGroupParser
    extend ParsingMethods

    MAPPINGS = [
      ['partyQualifierID', 'ID'],
      ['partyQualifierType', 'Typ', :to_i]
    ].freeze
  end
end
