# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom mapping rule for holdings information located in an Alma-specific datafield (AVA).
      class PhysicalLocationField < DataField
        # Extracting physical location information from AVA field.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri
        def perform(field)
          location = extract_location(field)
          return [] unless location

          [{ value: location }]
        end

        # Extracting physical location only if subfield 8 is populated.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def perform?(field)
          super && field.subfield_at('8').present?
        end

        private

        # Extracting subfields manually so that we can control the order. Without this customization, the
        # library name (in subfield q) would appear last.
        #
        # Documentation about the subfields available:
        # https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicw==/
        #
        # @return [String]
        def extract_location(datafield)
          [datafield.subfield_at('q'),
           datafield.subfield_at('c'),
           datafield.subfield_at('d')].join(', ')
        end
      end
    end
  end
end
