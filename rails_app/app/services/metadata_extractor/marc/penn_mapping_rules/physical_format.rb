# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennMappingRules
      # Module that contains logic for extracting and mapping the physical format field. Includes logic
      # for choosing 655 values and logic for normalizing values to appropriate AAT terms (where applicable).
      class PhysicalFormat
        LCSH = 'lcsh'
        PREFERRED_AUTHORITIES = [AAT::AUTHORITY, LCSH, 'lcgft', 'rbmscv'].freeze

        # Path to mappings configuration.
        def self.mappings_path
          Rails.root.join('config/mappings/physical_format.yml')
        end

        # Extract authority from 655 field.
        def self.authority(datafield)
          return LCSH if datafield.indicator2 == '0'

          datafield.subfield_at('2')
        end

        # Mappings of physical format terms to AAT terms.
        def self.mappings
          @mappings ||= YAML.safe_load(File.read(mappings_path), aliases: true, symbolize_names: true)
                            .select { |a| a[:replace_with].present? }
        end

        # Logic to select physical format values from 655 field.
        def self.select?(datafield)
          PREFERRED_AUTHORITIES.include?(authority(datafield))
        end

        # Normalize 655 values by mapping them to AAT terms.
        #
        # @param datafield [MetadataExtractor::Marmite::Transformer::MARCDocument::DataField]
        # @param extracted_values [<Hash>] values extracted from the MARC field as defined
        # @return [Array<String>]
        def self.normalize(datafield, extracted_values)
          authority = authority(datafield)

          return extracted_values if authority == AAT::AUTHORITY

          uri = extracted_values[:uri]
          value = extracted_values[:value].delete_suffix('.') # Remove trailing period bc it's a legacy MARC practice.

          match = mappings.find do |mapping|
            (mapping[:uri] == uri || mapping[:value] == value) && mapping[:authority] == authority
          end

          match ? match[:replace_with].deep_dup : extracted_values
        end
      end
    end
  end
end
