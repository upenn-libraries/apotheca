# frozen_string_literal: true

module MetadataExtractor
  module MARC
    # Class containing field mapping and cleanup rules to use while transforming
    # a MARC record to Apotheca's descriptive metadata schema.
    class Rules
      class << self
        # MARC mappings for fields.
        def field_mappings
          @field_mappings ||= {}
        end

        # Cleanup tasks to be done after mapping is complete.
        def cleanups
          @cleanups ||= []
        end

        # Adds field_mapping.
        #
        # @param klass [Class] class defining the field mapping
        # @param config [Hash] options to be sent to the field mapping class
        # @option config [Symbol] :to (nil) Apotheca field name the extracted value should be mapped to
        def field_mapping(klass, **config)
          to = config.delete(:to)
          field_mappings[to] ||= []
          field_mappings[to] << klass.new(**config)
        end

        # Adds clean up rule.
        #
        # @param klass [Class] class defining cleanup rule
        # @param config [Hash] options to be sent to the cleanup class
        def cleanup(klass, **config)
          cleanups << klass.new(**config)
        end
      end

      # Base class for creating rules for mapping individual fields.
      class FieldMapping
        attr_reader :config

        def initialize(**config)
          @config = config
        end

        # Transform MARC field into a valid set of values for Apotheca's JSON metadata schema.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Array<Hash>] list of extracted values in hash containing a value and (optionally) a uri key
        def transform(field)
          raise NotImplementedError
        end

        # Returns whether the provided field can be transformed.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transform?(field)
          raise NotImplementedError
        end
      end

      # Base class for creating cleanup rules. These rules are applied to the
      # JSON after all the mappings have been completed.
      class Cleanup
        attr_reader :fields

        def initialize(fields:)
          @fields = fields
        end

        # Cleans up the values provided.
        #
        # @param _values [Array<Hash>] list of values for Apotheca metadata field
        def apply(_values)
          raise NotImplemented
        end

        # Returns whether the rule should be applied to the field provided.
        #
        # @param field [Symbol] json field name
        # @return [Boolean]
        def apply?(field)
          fields.include?(field)
        end
      end
    end
  end
end
