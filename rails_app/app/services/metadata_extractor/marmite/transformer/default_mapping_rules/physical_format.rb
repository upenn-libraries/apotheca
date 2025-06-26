# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    class Transformer
      class DefaultMappingRules
        # Module that contains logic for extracting and mapping the physical format field. Includes logic
        # for choosing 655 values and logic for normalizing values to appropriate AAT terms (where applicable).
        module PhysicalFormat
          LCGFT = 'lcgft'
          RBMSCV = 'rbmscv'

          PREFERRED_AUTHORITIES = [AAT::AUTHORITY, LCGFT, RBMSCV].freeze

          # Mapping non-aat physical format values to aat terms.
          MAP = [
            { value: 'Excerpts', uri: 'http://id.loc.gov/authorities/genreForms/gf2014026097',
              authority: LCGFT,  to: AAT::EXCERPTS },
            { value: 'Scores',  uri: 'http://id.loc.gov/authorities/genreForms/gf2014027077',
              authority: LCGFT, to: AAT::SCORES },
            { value: 'Notated music', uri: 'http://id.loc.gov/authorities/genreForms/gf2014027184',
              authority: LCGFT,       to: AAT::SHEET_MUSIC }
          ].freeze

          # Logic to select physical format values from 655 field.
          def self.select?(datafield)
            PREFERRED_AUTHORITIES.include?(datafield.subfield_at('2')) || datafield.indicator2 == '0'
          end

          # Normalize 655 values by mapping them to AAT terms.
          #
          # @param datafield [MetadataExtractor::Marmite::Transformer::MARCDocument::DataField]
          # @param extracted_values [<Hash>] values extracted from the MARC field as defined
          # @return [Array<String>]
          def self.normalize(datafield, extracted_values)
            authority = datafield.subfield_at('2')

            return extracted_values if authority == AAT::AUTHORITY

            uri = extracted_values[:uri]
            value = extracted_values[:value]

            match = MAP.find do |mapping|
              (mapping[:uri] == uri || mapping[:value] == value) && mapping[:authority] == authority
            end

            match ? match[:to].deep_dup : extracted_values
          end
        end
      end
    end
  end
end
