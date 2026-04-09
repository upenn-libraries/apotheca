# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Excludes values that start with PRO or CHR. This is a legacy practice that is no longer recommended.
      class ExcludeLegacyValuesField < DataField
        LEGACY_VALUE_REGEX = /(PRO|CHR)\s/

        # Apply rule only if the value does not start with CHR or PRO.
        #
        # @return [Boolean]
        def apply?(field)
          super && !field.subfield_at('a').starts_with?(LEGACY_VALUE_REGEX)
        end
      end
    end
  end
end
