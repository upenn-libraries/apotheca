# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      class V3
        # Builder for IIIF thumbnail structures
        class ThumbnailBuilder
          attr_reader :asset

          # @param asset [AssetResource]
          def initialize(asset)
            @asset = asset
          end

          # Build thumbnail structure for manifest
          #
          # @return [Hash] IIIF thumbnail structure
          def build
            return {} unless asset&.iiif_image

            {
              'id' => iiif_api.image_url(size: '!600,600'),
              'type' => 'Image',
              'format' => 'image/jpeg',
              'service' => [thumbnail_service]
            }
          end

          private

          def iiif_api
            asset.iiif_api
          end

          # Build thumbnail service structure
          #
          # @return [Hash] IIIF image service structure
          def thumbnail_service
            {
              'id' => iiif_api.base_url,
              'type' => 'ImageService3',
              'profile' => 'level2'
            }
          end
        end
      end
    end
  end
end
