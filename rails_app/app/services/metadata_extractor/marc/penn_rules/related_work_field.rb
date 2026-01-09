# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom mapping rule to extract related works that are stored in the 7XX fields.
      class RelatedWorkField < DataField
        # Initializes related work rule and sets default prefix value.
        def initialize(**config)
          super

          @config[:prefix] = 'Related Work: '
        end

        # Only maps field if it is a related work.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def apply?(field)
          super && related_work?(field)
        end

        private

        # Field is a related work if a subfield t is present.
        def related_work?(field)
          field.subfield_at('t').present?
        end
      end
    end
  end
end
