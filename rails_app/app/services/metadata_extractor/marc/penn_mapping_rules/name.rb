# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennMappingRules
      # Module that contains logic for extracting and mapping the name field.
      module Name
        PROVENANCE_NAME_VALUES = %w[donor owner].freeze

        # Adding role value to name.
        def self.add_role_to_name(datafield, extracted_values)
          role_subfield = %w[111 711].include?(datafield.tag) ? 'j' : 'e'

          extracted_values.tap do |values|
            if (role = datafield.subfield_at(role_subfield))
              values[:role] = [{ value: role }]
            end
          end
        end

        # Return true if field is actually a name value and not a provenance or related work value.
        # Note: This should only be used for the 700 field because only this name field holds provenance values.
        def self.name?(datafield)
          !provenance?(datafield) && !related_work?(datafield)
        end

        # Return true if the role for the name is a provenance role.
        # Note: This should only be used for the 700 field.
        def self.provenance?(datafield)
          role = datafield.subfield_at('e')
          return false unless role

          PROVENANCE_NAME_VALUES.any? { |value| role.downcase.include?(value) }
        end

        # Return true if name is actually a related work.
        # Only for 700/710/711 fields, related works have a subfield t.
        def self.related_work?(datafield)
          datafield.subfield_at('t').present?
        end
      end
    end
  end
end
