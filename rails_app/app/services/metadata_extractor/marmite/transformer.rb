# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    # Transforms MARC XML into json-based descriptive metadata. The mapping rules specify what mappings actually are.
    # This class reads in the MARC XML and extracts the data based on the mapping rules given.
    class Transformer
      attr_reader :marc, :mappings

      # @param marc_xml [String]
      # @param mappings [MetadataExtractor::Marmite::Transformer::MappingRules]
      def initialize(marc_xml, mappings: DefaultMappingRules)
        @marc = MARCDocument.new(marc_xml)
        @mappings = mappings
      end

      # Converts MARC XML (provided by Marmite) to descriptive metadata fields.
      def to_descriptive_metadata
        mapped_values = {}

        # Map control fields
        (marc.controlfields + marc.datafields).each do |marc_field|
          mappings.rules_for(marc_field.type, marc_field.tag).each do |config|
            field = config[:to] # descriptive metadata field name

            next if config[:if] && !config[:if].call(marc_field)

            values = config.slice(:value, :uri)
                           .transform_values { |c| marc_field.values_at(**c.except(:join)).join(c[:join]) }
                           .compact_blank

            values = config[:custom].call(marc_field, values) if config[:custom]

            next if values.blank?

            mapped_values[field] ||= []
            mapped_values[field] << values
          end
        end

        # TODO: Could make these into a config value.
        strip_punctuation!(mapped_values, %i[subject geographic_subject physical_format publisher name])
        remove_duplicates!(mapped_values, %i[subject name language])

        mapped_values
      rescue StandardError => e
        raise StandardError, "Error mapping MARC XML: #{e.class} #{e.message}", e.backtrace
      end

      private

      # Strip punctuation from selected fields.
      def strip_punctuation!(mapped_values, fields)
        fields.each do |f|
          next unless mapped_values.key?(f)

          mapped_values[f]&.each do |h|
            # Remove trailing commas and semicolons
            h[:value].sub!(/\s*[,;]\s*\Z/, '')

            # Remove periods that are not preceded by a capital letter (could be an abbreviation).
            h[:value].sub!(/(?<![A-Z])\s*\.\s*\Z/, '')
          end
        end
      end

      # Removing duplicate values from selected fields.
      def remove_duplicates!(mapped_values, fields)
        fields.each do |f|
          next unless mapped_values.key?(f)

          mapped_values[f]&.uniq!
        end
      end
    end
  end
end