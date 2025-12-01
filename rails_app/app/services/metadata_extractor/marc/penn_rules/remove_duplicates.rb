# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Custom cleanup rule to remove duplicate values.
      class RemoveDuplicates < Rules::FieldCleanup
        # @param values [Array<Hash>]
        # @return [Array<Hash>]
        def apply(values)
          remove_duplicates(values)
        end

        private

        # Remove duplicate values.
        #
        # @param values [Array<Hash>]
        # @return [Array<Hash>]
        def remove_duplicates(values)
          values.group_by { |i| i.except(:uri) }
                .values
                .collect_concat { |v| preferred_value(v) }
        end

        # Selecting preferred values in a list of descriptive metadata values. It first removes any duplicates, then
        # prefers value with LOC URI, followed by values with any URI.
        #
        # @param values [Array<Hash>]
        # @return [Array<Hash>]
        def preferred_value(values)
          values = values.uniq

          loc_headings = values.select { |v| v[:uri]&.starts_with?(%r{https*://id\.loc\.gov/}) }
          return loc_headings if loc_headings.present?

          with_uris = values.select { |v| v[:uri].present? }
          return with_uris if with_uris.present?

          values
        end
      end
    end
  end
end
