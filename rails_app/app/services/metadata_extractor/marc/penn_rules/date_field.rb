# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom transformation rule to extract date and date ranges from the 008 field. Converts the date or range
      # to EDTF.
      class DateField < Rules::FieldMapping
        UNKNOWN_DATE = 'uuuu'

        attr_reader :tag

        # Initializer for rule to extract date and date ranges.
        #
        # @param tag [String] name of controlfield
        def initialize(tag:)
          @tag = tag
        end

        # Extract EDTF date from controlfield.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::ControlField]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri
        def transform(field)
          date = edtf_date(field)
          date.blank? ? [] : [{ value: date }]
        end

        # Only use this rule on control fields.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transform?(field)
          field.controlfield? && field.tag == tag
        end

        private

        # Extracting EDTF date from 008 controlfield.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::ControlField]
        # @return [String]
        def edtf_date(field)
          date1 = field.values_at(chars: 7..10).join # 7 - 10
          date2 = field.values_at(chars: 11..14).join # 11 - 14

          return unless date1 || date2

          if range?(field)
            edtf_range(date1, date2)
          else
            edtf_year(date1)
          end
        end

        # Returns whether the date in 008 field is a range.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::ControlField]
        # @return [Boolean]
        def range?(field)
          field.values_at(chars: 6).first.in? %w[i k m]
        end

        # Convert two dates to EDTF range.
        #
        # @param start [String] start date
        # @param finish [String] end date
        # @return [String|nil]
        def edtf_range(start, finish)
          return if start == UNKNOWN_DATE && finish == UNKNOWN_DATE

          "#{start}/#{finish}".gsub(/#{UNKNOWN_DATE}/, '').tr('u', 'X')
        end

        # Convert years to EDTF.
        #
        # @param year [String]
        # @return [String|nil]
        def edtf_year(year)
          return if year == UNKNOWN_DATE

          year.tr('u', 'X')
        end
      end
    end
  end
end
