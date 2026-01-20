# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Extracts provenance from name fields. This mapping should only be used for the 700 and 710 field.
      class ProvenanceNameField < DataField
        include AdditionalNameHelper

        # Only maps field if it's a role that implies it is a provenance name.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def apply?(field)
          super && provenance?(field)
        end
      end
    end
  end
end
