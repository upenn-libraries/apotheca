# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom logic for extracting and normalizing the 655 datafield to an AAT term. Includes logic
      # for choosing fields with valid authorities and normalizing values to appropriate AAT terms (if necessary).
      class PhysicalFormatField < DataField
        AAT = 'aat'
        LCSH = 'lcsh'
        PREFERRED_AUTHORITIES = [AAT, LCSH, 'lcgft', 'rbmscv'].freeze

        # Extracting value from datafield and then mapping to AAT term.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri
        def mapping(field)
          extracted_values = super

          return [] if extracted_values.empty?

          authority = authority(field)

          extracted_values.map do |extracted_value|
            next extracted_value if authority == AAT

            normalize(extracted_value, authority)
          end
        end

        # Mapping field only if it is part of the preferred authority.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def apply?(field)
          super && PREFERRED_AUTHORITIES.include?(authority(field))
        end

        private

        # Map term to AAT term, if mapping is available.
        #
        # @param extracted_value [Hash] value with value and uri key
        # @param authority [String] authority of extracted value
        # @return [Array<Hash>] containing value and uri keys
        def normalize(extracted_value, authority)
          uri = extracted_value[:uri]
          value = extracted_value[:value].delete_suffix('.') # Remove trailing period bc it's a legacy MARC practice.

          match = mappings.find do |mapping|
            (mapping[:uri] == uri || mapping[:value] == value) && mapping[:authority] == authority
          end

          match ? match[:replace_with].deep_dup : extracted_value
        end

        # Extract authority from 655 field.
        def authority(datafield)
          return LCSH if datafield.indicator2 == '0'

          datafield.subfield_at('2')
        end

        # Mappings of physical format terms to AAT terms.
        def mappings
          @mappings ||= YAML.safe_load(File.read(mappings_path), aliases: true, symbolize_names: true)
                            .select { |a| a[:replace_with].present? }
        end

        # Path to mappings configuration.
        def mappings_path
          Rails.root.join('config/mappings/physical_format.yml')
        end
      end
    end
  end
end
