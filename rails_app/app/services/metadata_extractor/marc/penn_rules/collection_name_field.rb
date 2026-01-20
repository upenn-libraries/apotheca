# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Extracts collection name from name fields. This mapping should only be used for the 710 field.
      class CollectionNameField < DataField
        include AdditionalNameHelper

        # Returns true if name field is a collection name.
        #
        # @return [Boolean]
        def apply?(field)
          super && collection?(field)
        end
      end
    end
  end
end
