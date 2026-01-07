# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # General mapping rule to use for MARC datafield with straight-forward mappings.
      class DataField < Rules::FieldMapping
        DEFAULT_SUBFIELDS = '*'
        DEFAULT_JOIN = ' '

        attr_reader :config

        # Initialize rule to transform MARC datafield to Apotheca's JSON metadata schema.
        #
        # @param config [Hash] options to use when choosing and extracting value from datafield
        # @option config [String] :tag (nil) name of datafield, used when choosing datafield
        # @option config [String] :indicator2 (nil) indicator2 value, used when choosing datafield
        # @option config [Array|String] :subfields ('*') subfields to extract
        # @option config [String] :join (' ') string to use when appending subfields
        # @option config [String|nil] :prefix (nil) prefix to add to extracted value
        # @option config [Boolean] :uri (false) whether to extract uri from subfield 0
        def initialize(**config)
          @config = config
        end

        # Transform datafield to JSON metadata field value. Retrieves appends all the subfields together
        # with a space to return one value from the field. Additionally, supports extracting URIs for terms as well.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri
        def transform(field)
          value = transform_value(field)
          uri = transform_uri(field)

          return [] if value.blank?

          [{ value: value, uri: uri }.compact_blank]
        end

        # Return whether datafield should be transformed using this rule.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transform?(field)
          field.datafield? && matching_tag?(field) && matching_indicator2?(field)
        end

        private

        # Returns true if the tag of the field matches.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Boolean]
        def matching_tag?(field)
          field.tag == config[:tag]
        end

        # Returns true if there is no indicator2 to match against or if the indicator2 value matches.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Boolean]
        def matching_indicator2?(field)
          config[:indicator2].nil? || field.indicator2 == config[:indicator2]
        end

        # Retrieve value from datafield.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [String]
        def transform_value(field)
          field.values_at(subfields: config.fetch(:subfields, DEFAULT_SUBFIELDS))
               .join(config.fetch(:join, DEFAULT_JOIN))
               .prepend(config.fetch(:prefix, ''))
        end

        # Retrieve uri from datafield.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [String]
        def transform_uri(field)
          return unless config[:uri]

          field.values_at(subfields: '0').first
        end
      end
    end
  end
end
