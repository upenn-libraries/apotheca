# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom transformation rule to extract transliterated titles from the 880 datafield.
      class TransliteratedTitleField < DataField
        # Only transform values that contain a transliterated title.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transform?(field)
          super && transliterated_title?(field)
        end

        private

        # Checking subfield 6 to see if the datafield given contains a transliterated title.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transliterated_title?(field)
          field.subfield_at('6').present? && field.subfield_at('6').match?(/\A245-\d{2}/)
        end
      end
    end
  end
end
