# frozen_string_literal: true

module MetadataExtractor
  module MARC
    # Transforms MARC XML into Apotheca's JSON-based descriptive metadata.
    #
    # The rules provided specify the field mappings and clean up rules that should be applied
    # when extracting the data.
    class Transformer
      # Initialize transformer object.
      #
      # @param rules [MetadataExtractor::MARC::Rules] field mappings and cleanup rules
      def initialize(rules: PennRules)
        @rules = rules
      end

      # Given a MARC XML document and a set of field mapping and cleanup rules, map the
      # leader, controlfields and datafields in the MARC record to Apotheca's descriptive metadata schema.
      def run(xml)
        marc = MARC::XMLDocument.new(xml)
        descriptive_metadata = {}

        @rules.each do |field_rules|
          values = field_rules.extract_values(marc)
          values = field_rules.apply_cleanups(values)

          next if values.blank?

          descriptive_metadata[field_rules.name] = values
        end

        descriptive_metadata
      end
    end
  end
end
