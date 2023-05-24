# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    # Transforms MARC XML into descriptive metadata
    class Transformer
      attr_reader :xml

      def initialize(marc_xml)
        @xml = Nokogiri::XML(marc_xml)
        @xml.remove_namespaces!
      end

      # Converts marc xml (provided by Marmite) to PQC fields.
      # TODO: This should be broken up in smaller methods.
      def to_descriptive_metadata
        mapped_values = {}

        # Map control fields
        xml.xpath('//records/record/controlfield').each do |element|
          tag = element.attributes['tag'].value
          mapping_config = MarcMappings::CONTROL_FIELDS[tag]

          next if mapping_config.blank?

          Array.wrap(mapping_config).each do |config|
            field = config[:field]

            mapped_values[field] ||= []

            text = element.text
            text = config[:chars].map { |i| text.slice(i) }.join if config[:chars]

            mapped_values[field].push(text)
          end
        end

        # Map MARC fields
        xml.xpath('//records/record/datafield').each do |element|
          tag = element.attributes['tag'].value
          mapping_config = MarcMappings::MARC_FIELDS[tag]

          next if mapping_config.blank?

          Array.wrap(mapping_config).each do |config|
            field = config[:field]
            selected_subfields = Array.wrap(config[:subfields])

            mapped_values[field] ||= []

            values = element.xpath('subfield')
            if selected_subfields.first != '*'
              values = values.select do |s|
                selected_subfields.include?(s.attributes['code'].value)
              end
            end
            values = values.map { |v| v&.text&.strip }.compact_blank!

            if (delimeter = config[:join])
              mapped_values[field].push values.join(delimeter)
            else
              mapped_values[field].concat values
            end
          end
        end

        # Adding item_type when conditions are met
        if manuscript?
          mapped_values['item_type'] = ['Manuscripts']
        elsif book?
          mapped_values['item_type'] = ['Books']
        end

        # Converting language codes to english name.
        languages = mapped_values.fetch('language', [])
        mapped_values['language'] = languages.filter_map { |l| ISO_639.find_by_code(l)&.english_name }

        # Adding call number
        mapped_values['call_number'] = xml.xpath('//records/record/holdings/holding/call_number')
                                          .filter_map(&:text)

        # Removing duplicate values from selected fields.
        %w[subject corporate_name personal_name language].each { |f| mapped_values[f]&.uniq! }

        # Cleanup
        mapped_values.transform_values! { |values| values.map(&:strip).compact_blank }.compact_blank!

        # Join fields if they aren't multivalued.
        mapped_values.each do |k, v|
          next if MarcMappings::MULTIVALUED_FIELDS.include?(k)

          mapped_values[k] = [v.join(' ')]
        end

        mapped_values
      rescue StandardError => e
        raise StandardError, "Error mapping MARC XML: #{e.class} #{e.message}", e.backtrace
      end

      private

      # Returns true if the MARC data describes the item as a Manuscript
      def manuscript?
        manuscript = false

        # Checking for values in field 040 subfield e
        subfield_e = xml.xpath("//records/record/datafield[@tag=040]/subfield[@code='e']").map(&:text)
        values = %w[appm appm2 amremm dacs dcrmmss]
        manuscript = true if subfield_e.any? { |s| values.include? s.downcase }

        # Checking for value in all subfield of field 040
        all_subfields = xml.xpath('//records/record/datafield[@tag=040]/subfield').map(&:text)
        manuscript = true if all_subfields.any? { |s| s.casecmp('paulm').zero? }

        manuscript
      end

      # Returns true if the MARC data describes the item as a Book
      def book?
        # Checking for `a` in 7th value of the leader field
        leader = xml.at_xpath('//records/record/leader')&.text
        return if leader.blank?

        leader[6] == 'a'
      end
    end
  end
end
