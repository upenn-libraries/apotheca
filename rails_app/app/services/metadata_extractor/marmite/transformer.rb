# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    # Transforms MARC XML into json-based descriptive metadata. The mapping rules specify what mappings actually are,
    # this class implements the mapping configuration.
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

        # TODO: Is this mapping still needed?
        # Adding item_type when conditions are met
        # if manuscript?
        #   mapped_values[:item_type] = [{ value: 'Manuscripts' }] # TODO: need a URI
        # elsif book?
        #   mapped_values[:item_type] = [{ value: 'Books' }] # TODO: need a URI
        # end

        # Removing duplicate values from selected fields.
        %i[subject name language].each { |f| mapped_values[f]&.uniq! }

        # TODO: might need to strip punctuation from values.

        mapped_values
      rescue StandardError => e
        raise StandardError, "Error mapping MARC XML: #{e.class} #{e.message}", e.backtrace
      end

      private

      # Returns true if the MARC data describes the item as a Manuscript
      def manuscript?
        manuscript = false

        # Checking for values in field 040 subfield e
        subfield_e = marc.xpath("//records/record/datafield[@tag=040]/subfield[@code='e']").map(&:text)
        values = %w[appm appm2 amremm dacs dcrmmss]
        manuscript = true if subfield_e.any? { |s| values.include? s.downcase }

        # Checking for value in all subfield of field 040
        all_subfields = marc.xpath('//records/record/datafield[@tag=040]/subfield').map(&:text)
        manuscript = true if all_subfields.any? { |s| s.casecmp('paulm').zero? }

        manuscript
      end

      # Returns true if the MARC data describes the item as a Book
      def book?
        # Checking for `a` in 7th value of the leader field
        leader = marc.at_xpath('//records/record/leader')&.text
        return if leader.blank?

        leader[6] == 'a'
      end
    end
  end
end
