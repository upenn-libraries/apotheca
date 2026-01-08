# frozen_string_literal: true

module MetadataExtractor
  module MARC
    # Class containing field mapping and cleanup rules to use while transforming
    # a MARC record to Apotheca's descriptive metadata schema.
    class Rules
      class << self
        extend Enumerable

        # Defining each so class can be used as an enumerable to iterate over field rules.
        def each(&block)
          field_rules.each(&block)
        end

        # Rules for each descriptive metadata field.
        #
        # @return [Array<FieldRules>]
        def field_rules
          @field_rules ||= []
        end

        # Add rules (mapping and cleanup) for one particular (Apotheca descriptive metadata) field.
        #
        # @param field [Symbol] field name
        # @return [MetadataExtractor::MARC::Rules::FieldRules]
        def add_rules(field:, &block)
          field_rules << FieldRules.new(field).tap(&block)
        end
      end

      # Class containing mappings and cleanup rules for one descriptive metadata field.
      class FieldRules
        attr_reader :name, :mappings, :cleanups

        # Create object to store field mappings and field cleanings.
        #
        # @param name [String] Apotheca descriptive metadata field rules should be applied for
        def initialize(name)
          @name = name
          @mappings = []
          @cleanups = []
        end

        # Adds mapping rule.
        #
        # @param klass [Class] class defining the field mapping
        # @param config [Hash] options to be sent to the mapping class
        def mapping(klass, **config)
          mappings << klass.new(**config)
        end

        # Adds cleanup rule.
        #
        # @param klass [Class] class defining cleanup rule
        # @param config [Hash] options to be sent to the cleanup class
        def cleanup(klass, **config)
          cleanups << klass.new(**config)
        end

        # Transform MARC to values for Apotheca's descriptive metadata schema
        # using this field's mappings and cleanup rules.
        #
        # @param marc [MetadataExtractor::MARC::XMLDocument]
        # @return [Array<Hash>] values for one Apotheca descriptive metadata field
        def transform(marc)
          values = apply_mappings(marc)
          apply_cleanups(values)
        end

        # Extract values from MARC by running all the mapping rules for this field.
        #
        # @param marc [MetadataExtractor::MARC::XMLDocument]
        # @return [Array<Hash>] values for one Apotheca descriptive metadata field
        def apply_mappings(marc)
          marc.fields.flat_map do |field|
            mappings.flat_map do |m|
              m.apply(field)
            end
          end
        end

        # Apply cleanup rules to values that have been extracted.
        #
        # @param values [Array<Hash>] Apotheca descriptive metadata values
        # @return [Array<Hash>] Apotheca descriptive metadata values
        def apply_cleanups(values)
          cleanups.each do |cleanup|
            values = cleanup.apply(values)
          end

          values
        end
      end

      # Base class for rules that map marc fields to values for Apotheca's JSON metadata schema.
      class FieldMapping
        attr_reader :config

        def initialize(**config)
          @config = config
        end

        # Perform mapping for field, only if rule should be applied.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Array<Hash>] list of extracted values in hash containing a value and (optionally) a uri key
        # @return [Array] return empty array if field should not be used with this mapping
        def apply(field)
          return [] unless apply?(field)

          mapping(field)
        end

        # Mapping for MARC field into a valid set of values for Apotheca's JSON metadata schema.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Array<Hash>] list of extracted values in hash containing a value and (optionally) a uri key
        def mapping(field)
          raise NotImplementedError
        end

        # Returns whether the provided field can be mapped.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def apply?(field)
          raise NotImplementedError
        end
      end

      # Base class for creating cleanup rules.
      # These rules are applied to all the values after they are extracted from MARC.
      class FieldCleanup
        # Cleans up the values provided.
        #
        # @param values [Array<Hash>] list of values for Apotheca metadata field
        def apply(values)
          raise NotImplementedError
        end
      end
    end
  end
end
