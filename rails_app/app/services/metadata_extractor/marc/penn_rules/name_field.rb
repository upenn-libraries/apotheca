# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom mapping rule to include the name's role when extracting it from the datafield.
      class NameField < DataField
        # Extracting name value, uri and role.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Array<Hash>] list of extracted values in hash containing value, uri and roles
        def perform(field)
          super.map do |value|
            extracted_roles = roles(field)
            value[:role] = extracted_roles.map { |r| { value: r } } if extracted_roles.present?
            value
          end
        end

        private

        # Return roles for datafield given.
        #
        # @return [Array<String>]
        def roles(field)
          role_subfield = %w[111 711].include?(field.tag) ? 'j' : 'e'
          field.values_at(subfields: role_subfield)
        end
      end
    end
  end
end
