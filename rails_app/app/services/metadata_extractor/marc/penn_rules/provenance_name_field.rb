# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Extracts provenance from name fields. This mapping should only be used for the 700 field.
      class ProvenanceNameField < DataField
        ROLE_REGEX = /(donor|owner)/

        # Only maps field if it's a role that implies it is a provenance name.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def perform?(field)
          super && provenance?(field)
        end

        private

        # Return true if the role for the name is a provenance role.
        # Note: Provenance name values are only contained in the 700 field.
        def provenance?(field)
          role = field.subfield_at('e')

          role.present? && role.match?(ROLE_REGEX)
        end
      end
    end
  end
end
