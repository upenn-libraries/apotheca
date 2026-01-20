# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom mapping rule for 7XX name fields. Excludes fields that are related works, collection names or
      # provenance names. Includes roles in the extracted value.
      class AdditionalNameField < NameField
        include AdditionalNameHelper

        # Extracting name value, uri and roles. When extracting roles, makes sure to remove any provenance roles.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Array<Hash>] list of extracted values in hash containing value, uri and roles
        def mapping(field)
          super.map do |value|
            extracted_roles = name_roles(field)
            value[:role] = extracted_roles.map { |r| { value: r } } if extracted_roles.present?
            value
          end
        end

        # Only maps datafields that don't contain related work, collection or provenance values.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def apply?(field)
          super && name?(field)
        end
      end
    end
  end
end
