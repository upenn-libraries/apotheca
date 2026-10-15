# frozen_string_literal: true

module Item
  # Transform descriptive medata into exportable format
  module Exportable
    # @return [Hash]
    def to_json_export
      attributes.slice(*ItemResource::DescriptiveMetadata::Fields.all)
                .transform_values { |v| v.map(&:to_json_export) }
                .compact_blank
    end
  end
end
