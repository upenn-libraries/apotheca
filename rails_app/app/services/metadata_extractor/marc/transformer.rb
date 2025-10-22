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
        json = transform(marc)

        cleanup(json)
      end

      private

      # Apply field mapping rules to transform MARC XML to Apotheca's descriptive metadata schema.
      #
      # @param marc [MetadataExtractor::MARC::XMLDocument]
      # @return [Hash<Symbol, Array<Hash>] Apotheca descriptive metadata
      def transform(marc)
        @rules.field_mappings.transform_values do |mappings|
          marc.fields.flat_map do |field|
            mappings.flat_map do |m|
              next [] unless m.transform?(field)

              m.transform(field)
            end
          end
        end
      end

      # Apply cleanup rules to values that have been extracted and formated into Apotheca's descriptive
      # metadata schema.
      #
      # @param json [Hash<Symbol, Array<Hash>] Apotheca descriptive metadata
      # @return [Hash<Symbol, Array<Hash>] Apotheca descriptive metadata
      def cleanup(json)
        json.each do |field, values|
          @rules.cleanups.each do |rule|
            next unless rule.apply?(field)

            values = rule.apply(values)
          end

          json[field] = values
        end

        json.compact_blank
      end
    end
  end
end
