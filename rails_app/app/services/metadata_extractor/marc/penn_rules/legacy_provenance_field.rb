# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Extracts provenance from 650$a. This is a legacy practice that is no longer used, but we need to
      # continue to accommodate.
      class LegacyProvenanceField < DataField
        PRO = 'PRO '

        # After extracting mapped value, delete the PRO prefix.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri
        def mapping(field)
          super.map do |extracted_value|
            extracted_value[:value] = extracted_value[:value].delete_prefix(PRO)
            extracted_value
          end
        end

        # Only applies this mapping if the field starts with PRO.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Boolean]
        def apply?(field)
          super && field.subfield_at('a').starts_with?(PRO)
        end
      end
    end
  end
end
