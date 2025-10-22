# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom rule for extracting language from a MARC datafield (041) and MARC controlfield (008).
      class LanguageField < Rules::FieldMapping
        attr_reader :config

        # Initialize rule to transform language in MARC control field or datafield to Apotheca's JSON metadata schema.
        #
        # @param config [Hash] options to use when choosing and extracting value from datafield/controlfield.
        # @option config [String] :tag (nil) name of field, used when choosing field
        # @option config [Array|Range|String] :subfields ('*') subfields to extract
        # @option config [Array|Range|String] :chars (nil) characters to extract
        def initialize(**config)
          @config = config
        end

        # Extracts language codes from datafield/controlfield and maps them to the appropriate value/uri.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri
        def transform(field)
          extract_language_codes(field).filter_map do |code|
            normalize_language(code)
          end
        end

        # Transforms controlfields or datafields that contain a matching tag.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transform?(field)
          %i[datafield controlfield].include?(field.type) && field.tag == config[:tag]
        end

        private

        # Retrieve language codes from datafield or controlfield.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Array<String>]
        def extract_language_codes(field)
          case field.type
          when :datafield
            field.values_at(subfields: config[:subfields])
          when :controlfield
            [field.values_at(chars: config[:chars]).join]
          end
        end

        # Normalize language code to ISO-639 english name and URI.
        #
        # @param code [String]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri keys
        def normalize_language(code)
          language = ISO_639.find_by_code(code)

          return if language.nil?

          { value: language.english_name, uri: "http://id.loc.gov/vocabulary/iso639-2/#{language.alpha3}" }
        end
      end
    end
  end
end
