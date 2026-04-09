# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Helper to be mixed into mapping rules for 7XX fields.
      module AdditionalNameHelper
        PROVENANCE_TAG_REGEX = /(700|710)/
        PROVENANCE_ROLE_REGEX = /(donor|owner)/

        COLLECTION_TAG = '710'
        COLLECTION_SUBFIELD_5 = 'PU'

        # Return roles for datafield given.
        #
        # @return [Array<String>]
        def roles(field)
          role_subfield = field.tag == '711' ? 'j' : 'e'
          field.values_at(subfields: role_subfield)
        end

        # Return if field should be considered a name field.
        #
        # @return [Boolean]
        def name?(field)
          !related_work?(field) && !collection?(field) && name_role?(field)
        end

        # Return true if field is a related work.
        #
        # @return [Boolean]
        def related_work?(field)
          field.subfield_at('t').present?
        end

        # Return if field should be considered a provenance field.
        #
        # @return [Boolean]
        def provenance?(field)
          field.tag.match?(PROVENANCE_TAG_REGEX) && provenance_role?(field)
        end

        # Return if field should be considered a collection name. Collection names are identified
        # by having a 'PU' value in subfield 5.
        #
        # @return [Boolean]
        def collection?(field)
          field.tag.match?(COLLECTION_TAG) && field.subfield_at('5') == COLLECTION_SUBFIELD_5
        end

        # Returns true if field contains at least one provenance role
        #
        # @return [Boolean]
        def provenance_role?(field)
          roles(field).any? { |role| role.match?(PROVENANCE_ROLE_REGEX) }
        end

        # Returns true if field contains no roles or at least one valid name role.
        #
        # @return [Boolean]
        def name_role?(field)
          roles(field).blank? || name_roles(field).present?
        end

        # Return name roles. This removes any provenance roles from all the roles present.
        #
        # @return [Array<String>]
        def name_roles(field)
          roles(field).reject { |role| role.match?(PROVENANCE_ROLE_REGEX) }
        end
      end
    end
  end
end
