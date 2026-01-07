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

        # Extract values from MARC following the mapping rules for this field.
        #
        # @param marc [MetadataExtractor::MARC::XMLDocument]
        # @return [Array<Hash>] values for one Apotheca descriptive metadata field
        def extract_values(marc)
          marc.fields.flat_map do |field|
            mappings.flat_map do |m|
              next [] unless m.transform?(field)

              m.transform(field)
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

      # Base class for creating rules for mapping marc fields.
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

      # Base class for creating cleanup rules.
      # These rules are applied to all the values after they are extracted from MARC.
      class FieldCleanup
        # Cleans up the values provided.
        #
        # @param _values [Array<Hash>] list of values for Apotheca metadata field
        def apply(_values)
          raise NotImplementedError
        end
      end
    end
  end
end
