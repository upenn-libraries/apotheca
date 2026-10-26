# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom mapping rule to extract BCE date and date ranges from the 046 field.
      # Converts the date or range to EDTF.
      class SpecialCodedDateField < DateField
        # Only use this rule on 046 fields where sf a suggests a date or range of the type we want.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def apply?(field)
          return false unless bc_date_indicated?(field.document)

          field.tag == tag && field.datafield?
        end

        private

        # Extracting EDTF date from 046 controlfield.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::ControlField]
        # @return [String]
        def edtf_date(field)
          date1 = bce_year(field.subfield_at(:b))
          date2 = bce_year(field.subfield_at(:d))

          return unless date1 || date2

          if range?(field)
            edtf_range(date1, date2)
          else
            edtf_year(date1)
          end
        end

        # Format a BCE year with a hyphen and left-padded zeroes
        # @param [String, nil] value
        # @return [String, nil]
        def bce_year(value)
          return unless value

          "-#{value.rjust(4, '0')}"
        end

        # Returns whether the date in 046 field is a range. This is based on DtSt value in sf a.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::ControlField]
        # @return [Boolean]
        def range?(field)
          field.subfield_at(:a).in?(%w[i k m q])
        end
      end
    end
  end
end
