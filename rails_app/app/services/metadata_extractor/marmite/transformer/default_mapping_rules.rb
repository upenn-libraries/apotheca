# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    class Transformer
      # Default mappings rules for converting Penn's MARC XML to Apotheca's descriptive metadata schema.
      # @see MappingRules
      class DefaultMappingRules < MappingRules
        SPACE = ' '
        ALL = '*'
        A_TO_Z = ('a'..'z').to_a
        PROVENANCE_NAME_VALUES = %w[donor owner].freeze

        # Mapping language to standardized ISO639 english name and URI.
        def self.language_transformation(_, extracted_values)
          code = extracted_values[:value]
          if (language = ISO_639.find_by_code(code))
            { value: language.english_name, uri: "https://id.loc.gov/vocabulary/iso639-2/#{language.alpha3}" }
          else
            {}
          end
        end

        # Adding role value to name.
        def self.add_role_to_name(datafield, extracted_values)
          role_subfield = datafield.tag == '111' || datafield.tag == '711' ? 'j' : 'e'

          extracted_values.tap do |values|
            if (role = datafield.subfield_at(role_subfield))
              values[:role] = [{ value: role }]
            end
          end
        end

        # Check if the role is a provenance role.
        def self.role_is_provenance?(datafield)
          role = datafield.subfield_at('e')
          return false unless role

          PROVENANCE_NAME_VALUES.any? { |value| role.downcase.include?(value) }
        end

        # Adding location to the beginning of the value manually because currently the order of the fields is preserved.
        def self.prefixing_with_location(datafield, extracted_values)
          extracted_values.tap do |values|
            subfield_j = datafield.subfield_at('q')
            values[:value] = "#{subfield_j}, #{values[:value]}" if subfield_j
          end
        end

        # Return true if field contains a transliterated title
        def self.transliterated_title?(datafield)
          index = datafield.subfield_at('6')&.match(/\A245-(\d{2})/)
          return false unless index

          datafield.parent.xpath("datafield[@tag='245']/subfield[@code='6' and text()='880-#{index[1]}']").present?
        end

        # Applying some minor transformation to ensure the date value follows the EDTF spec.
        def self.convert_to_edtf(_, extracted_values)
          return {} if extracted_values[:value].blank? || extracted_values[:value].match?(/\Auuuu\Z/)

          extracted_values[:value] = extracted_values[:value].tr('u', 'X')
          extracted_values
        end

        map_controlfield '008', to: :date, value: { chars: (7..10).to_a }, custom: method(:convert_to_edtf)
        map_controlfield '008', to: :language, value: { chars: (35..37).to_a }, custom: method(:language_transformation)

        # Separate mappings for language ensure the language codes aren't appended together
        map_datafield '041', to: :language, value: { subfields: 'a' }, custom: method(:language_transformation)
        map_datafield '041', to: :language, value: { subfields: 'b' }, custom: method(:language_transformation)
        map_datafield '041', to: :language, value: { subfields: 'g' }, custom: method(:language_transformation)
        map_datafield '100', to: :name, value: { subfields: %w[a b c d q], join: SPACE }, uri: { subfields: '0' },
                             custom: method(:add_role_to_name)
        map_datafield '110', to: :name, value: { subfields: %w[a d], join: SPACE }, uri: { subfields: '0' },
                             custom: method(:add_role_to_name)
        map_datafield '111', to: :name, value: { subfields: %w[a d], join: SPACE }, uri: { subfields: '0' },
                             custom: method(:add_role_to_name)
        map_datafield '245', to: :title, value: { subfields: %w[a b f g k n p s], join: SPACE }
        map_datafield '246', to: :alt_title, value: { subfields: %w[a b n p], join: SPACE }
        map_datafield '260', to: :publisher, value: { subfields: 'b' }
        map_datafield '264', to: :publisher, value: { subfields: 'b' },
                             if: ->(datafield) { datafield.indicator2 == '1' }
        map_datafield '300', to: :extent, value: { subfields: %w[a b c e f g], join: SPACE }
        map_datafield '336', to: :item_type, value: { subfields: 'a' },
                             if: ->(datafield) { datafield.subfield_at('2') == 'rdacontent' },
                             custom: ->(_, values) { RDAContentTypeToDCMIType::MAP.fetch(values[:value], {}) }
        map_datafield '500', to: :note,      value: { subfields: 'a' }
        map_datafield '501', to: :note,      value: { subfields: 'a' }
        map_datafield '502', to: :note,      value: { subfields: ('a'..'o').to_a, join: SPACE }
        map_datafield '505', to: :note, value: { subfields: ALL, join: SPACE, prefix: 'Table of contents: ' }
        map_datafield '520', to: :description, value: { subfields: %w[a b], join: SPACE }
        map_datafield '542', to: :note, value: { subfields: ('a'..'s').to_a, join: SPACE }
        map_datafield '545', to: :note, value: { subfields: %w[a b u], join: SPACE }
        map_datafield '546', to: :note, value: { subfields: %w[a b], join: SPACE }
        map_datafield '561', to: :provenance, value: { subfields: 'a' }
        map_datafield '590', to: :note, value: { subfields: 'a' }
        map_datafield '600', to: :subject, value: { subfields: A_TO_Z, join: SPACE }, uri: { subfields: '0' }
        map_datafield '610', to: :subject, value: { subfields: A_TO_Z, join: ' -- ' }, uri: { subfields: '0' }
        map_datafield '648', to: :coverage, value: { subfields: %w[a y], join: ' -- ' }, uri: { subfields: '0' }
        map_datafield '650', to: :subject, value: { subfields: A_TO_Z, join: ' -- ' }, uri: { subfields: '0' }
        map_datafield '650', to: :coverage, value: { subfields: 'y' }
        map_datafield '651', to: :geographic_subject, value: { subfields: A_TO_Z, join: ' -- ' },
                             uri: { subfields: '0' }
        map_datafield '651', to: :coverage, value: { subfields: 'y' }
        map_datafield '655', to: :physical_format, value: { subfields: 'a' }, uri: { subfields: '0' }
        map_datafield '700', to: :provenance, value: { subfields: %w[a b c d e ], join: SPACE },
                             if: method(:role_is_provenance?)
        map_datafield '700', to: :name, value: { subfields: %w[a b c d q], join: SPACE },
                             uri: { subfields: '0' },
                             custom: method(:add_role_to_name), unless: method(:role_is_provenance?)
        map_datafield '710', to: :name, value: { subfields: %w[a b d], join: SPACE }, uri: { subfields: '0' },
                             custom: method(:add_role_to_name)
        map_datafield '711', to: :name, value: { subfields: %w[a d], join: SPACE }, uri: { subfields: '0' },
                             custom: method(:add_role_to_name)
        map_datafield '752', to: :location, value: { subfields: %w[a b c d f g h], join: ' -- ' },
                             uri: { subfields: '0' }
        map_datafield '773', to: :collection, value: { subfields: 't' }
        map_datafield '856', to: :relation, value: { subfields: %w[u z 3], join: ': ' }
        map_datafield '880', to: :title, value: { subfields: %w[a b f g k n p s] }, if: method(:transliterated_title?)

        # Mapping holdings information located in an Alma-specific datafield.
        # Documentation about the subfields available:
        # https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicw==/
        map_datafield 'AVA', to: :physical_location, value: { subfields: %w[c d], join: ', ' },
                             if: ->(datafield) { datafield.subfield_at('8').present? },
                             custom: method(:prefixing_with_location)
      end
    end
  end
end
