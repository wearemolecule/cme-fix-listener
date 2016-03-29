# The MetaParser is responsible for the <FIXML> mapping. This tag is one of many tags inside
# a FIXML message. To see a complete FIXML message there are many examples inside of spec/datafiles.
#
# Relevant FIXML Slice:
#
# <FIXML s="20090815" cv="CME.0001" xv="109" v="5.0 SP2">
#

module CmeFixListener
  # <FIXML> Mappings from abbreviations to full names
  class MetaParser
    extend ParsingMethods

    MAPPINGS = [
      ['customApplicationVersion', 'cv'],
      ['fixmlExtensionVersion', 'xv'],
      ['schemaReleaseDate', 's'],
      ['fixVersionNumber', 'v']
    ].freeze
  end
end
