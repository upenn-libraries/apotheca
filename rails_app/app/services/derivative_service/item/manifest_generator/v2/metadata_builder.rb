# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      class V2
        # Builder for IIIF Presentation v2 metadata.
        class MetadataBuilder
          attr_reader :item

          # @param [ItemPresenter]
          def initialize(item)
            @item = item
          end

          # Metadata to display in image viewer.
          def build
            [availability_metadata] + descriptive_metadata
          end

          private

          # Availability metadata showing the public URL
          #
          # @return [Hash] availability metadata structure
          def availability_metadata
            {
              label: 'Available Online',
              value: [digital_collections_url]
            }
          end

          # Build descriptive metadata from item fields
          #
          # @return [Array<Hash>] array of descriptive metadata structures
          def descriptive_metadata
            ItemResource::DescriptiveMetadata::Fields.all.filter_map do |field|
              values = item.descriptive_metadata.send(field)

              next if values.blank?

              { label: field.to_s.titleize, value: normalized_field_values(field, values) }
            end
          end

          # Normalize field values based on field type
          #
          # @param field [Symbol] the metadata field name
          # @param values [Array] the field values
          # @return [Array<String>] normalized values
          def normalized_field_values(field, values)
            case field
            when :rights
              values.pluck(:uri).map(&:to_s)
            when :name
              values.map do |v|
                roles = v[:role]&.pluck(:value)&.join(', ')
                roles.present? ? "#{v[:value]} (#{roles})" : v[:value]
              end
            else
              values.pluck(:value)
            end
          end

          # Link to item in Digital collections
          def digital_collections_url
            PublishingService::Endpoint.digital_collections.item_url(item.id)
          end
        end
      end
    end
  end
end
