# frozen_string_literal: true

# The PartyParser is responsible for the <Pty> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <Pty R="24" Src="C" ID="COMPANY001">
#

module CmeFixListener
  # <Pty> Mappings from abbreviations to full names (with types)
  class PartyParser
    extend ParsingMethods

    MAPPINGS = [
      ["partyID", "ID"],
      ["partyIDSource", "Src"],
      ["partyRole", "R", :to_i]
    ].freeze
  end
end
