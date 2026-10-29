# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom mapping rule to extract BCE date and date ranges from the 046 field.
      # Converts the date or range to EDTF using formatting methods from parent DateField class.
      class BCEDateField < DateField
        # Only use this rule on 046 fields where if the 008 controlfield indicates a BC date.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def apply?(field)
          return false unless bc_date?(field.document)

          field.datafield? && field.tag == tag
        end

        private

        # Extracting EDTF date from 046 datafield.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
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

        # Format a BCE year with a hyphen and left-padded zeroes.
        # @param value [String, nil]
        # @return [String, nil]
        def bce_year(value)
          return unless value

          value.rjust(4, '0').prepend('-')
        end

        # Returns whether the date in 046 field is a range. This is based on DtSt value in sf a.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::DataField]
        # @return [Boolean]
        def range?(field)
          field.subfield_at(:a).in?(%w[i k m q])
        end
      end
    end
  end
end
