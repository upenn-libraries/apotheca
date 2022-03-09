# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    class Transformer
      attr_reader :xml

      def initialize(marc_xml)
        @xml = Nokogiri::XML(marc_xml)
        @xml.remove_namespaces!
      end

      # Converts marc xml (provided by Marmite) to PQC fields.
      # TODO: This should be broken up in smaller methods. This mapping will
      # probably change, so I'll save the refactoring for when I know what those
      # changes are.
      def to_descriptive_metadata
        mapped_values = {}

        xml.xpath('//records/record/datafield').each do |element|
          tag = element.attributes['tag'].value
          next unless MarcMappings::TAGS[tag].present?

          if MarcMappings::TAGS[tag]['*'].present? # selecting all fields under the given tag
            header = pqc_field(tag, '*')
            mapped_values[header] ||= []
            values = element.children.map(&:text).delete_if { |v| v.strip.empty? }

            # Joining fields with a configured seperator and appending, otherwise concating values to array.
            if MarcMappings::ROLLUP_FIELDS[tag].present?
              seperator = MarcMappings::ROLLUP_FIELDS[tag]['separator']
              mapped_values[header].push(values.join(seperator))
            else
              mapped_values[header].concat(values)
            end
          else
            # if not selecting all
            if MarcMappings::ROLLUP_FIELDS[tag].present?
              rollup_values = []
              header = ''
              element.xpath('subfield').each do |subfield|
                # FIXME: If the headers are different for a field that rolls up, there are going to be problems.
                header = pqc_field(tag, subfield.attributes['code'].value)
                if header.present?
                  mapped_values[header] ||= []
                  values = subfield.children.map(&:text).delete_if { |v| v.strip.empty? }
                  rollup_values.concat(values)
                end
              end
              mapped_values[header] << rollup_values.join(MarcMappings::ROLLUP_FIELDS[tag]['separator']) if rollup_values
            else
              element.xpath('subfield').each do |subfield|
                header = pqc_field(tag, subfield.attributes['code'].value)
                if header.present?
                  mapped_values[header] ||= []
                  mapped_values[header].concat(subfield.children.map(&:text))
                end
              end
            end
          end
        end

        # Adding item_type when conditions are met
        if manuscript?
          mapped_values['item_type'] = ['Manuscripts']
        elsif book?
          mapped_values['item_type'] = ['Books']
        end

        # Adding bibnumber and call number
        bibnumber = xml.at_xpath('//records/record/controlfield[@tag=001]').text
        mapped_values['identifier'] ||= ["#{Settings.digital_object.repository_prefix}_#{bibnumber}"]
        mapped_values['call_number'] = xml.xpath('//records/record/holdings/holding/call_number')
                                           .map(&:text)
                                           .compact
        # Cleanup
        mapped_values.transform_values! { |values| values.map(&:strip).reject(&:empty?) }

        # Join fields if they aren't multivalued.
        mapped_values.each do |k, v|
          next if MarcMappings::MULTIVALUED_FIELDS.include?(k)
          mapped_values[k] = [v.join(' ')]
        end

        mapped_values
      rescue => e
        raise StandardError, "Error mapping MARC XML to PQC: #{e.class} #{e.message}", e.backtrace
      end

      private

      # Returns true if the MARC xml describes the item as a Manuscript
      def manuscript?
        manuscript = false

        # Checking for values in field 040 subfield e
        subfield_e = xml.xpath("//records/record/datafield[@tag=040]/subfield[@code='e']").map(&:text)
        manuscript = true if subfield_e.any? { |s| ['appm', 'appm2', 'amremm', 'dacs', 'dcrmmss'].include? s.downcase }

        # Checking for value in all subfield of field 040
        all_subfields = xml.xpath('//records/record/datafield[@tag=040]/subfield').map(&:text)
        manuscript = true if all_subfields.any? { |s| s.casecmp('paulm').zero? }

        manuscript
      end

      # Returns true if the MARC xml describes the item as a Book
      def book?
        # Checking for `a` in 7th value of the leader field
        leader = xml.at_xpath('//records/record/leader').text
        leader[6] == 'a'
      end

      def pqc_field(marc_field, code = '*')
        MarcMappings::TAGS[marc_field][code]
      end
    end
  end
end
