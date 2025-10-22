# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom cleanup rule to trim punctuation.
      class TrimPunctuation < Rules::Cleanup
        # Trim punctuation from values.
        #
        # @param values [Array<Hash>]
        # @return [Array<Hash>]
        def apply(values)
          values.map do |value|
            strip_punctuation(value)
          end
        end

        private

        # Strip punctuation from value.
        #
        # @param original_value [Hash]
        def strip_punctuation(original_value)
          cleaned_value = original_value.deep_dup

          # Remove trailing commas and semicolons
          cleaned_value[:value].sub!(%r{\s*[,;/:]\s*\Z}, '')

          # Remove periods that are not preceded by a capital letter (could be an abbreviation).
          cleaned_value[:value].sub!(/(?<![A-Z])\s*\.\s*\Z/, '')

          # Strip punctuation from role values as well.
          cleaned_value[:role] = cleaned_value[:role].map { |r| strip_punctuation(r) } if cleaned_value[:role].present?

          cleaned_value
        end
      end
    end
  end
end
