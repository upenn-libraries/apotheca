# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom transformation rule for 7XX name fields. Excludes fields
      # that are related work or provenance names. Includes name's roles
      # in the extracted value.
      class AdditionalNameField < NameField
        # Only transforms datafield that doesn't contain related work or provenance values.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transform?(field)
          super && !related_work?(field) && !provenance?(field)
        end

        private

        # Return true if field is a related work.
        #
        # @return [Boolean]
        def related_work?(field)
          field.subfield_at('t').present?
        end

        # Return true if field contains a provenance value.
        #
        # Note: Only 700 fields can contain a provenance value.
        #
        # @return [Boolean]
        def provenance?(field)
          field.tag == '700' && provenance_roles?(field)
        end

        # Returns true if field contains a provenance role.
        #
        # @return [Boolean]
        def provenance_roles?(field)
          roles(field).any? { |role| role.match?(ProvenanceNameField::ROLE_REGEX) }
        end
      end
    end
  end
end
