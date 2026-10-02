# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      class V3
        # Builder for IIIF Presentation v3 metadata.
        class MetadataBuilder
          attr_reader :item

          # @param [ItemPresenter]
          def initialize(item)
            @item = item
          end

          # Metadata to display in image viewer. Using V2 metadata builder as a starting point.
          def build
            metadata = V2::MetadataBuilder.new(item).build.map(&:stringify_keys)

            metadata.map do |field|
              field.transform_values do |v|
                { 'none' => Array.wrap(v) }
              end
            end
          end
        end
      end
    end
  end
end
