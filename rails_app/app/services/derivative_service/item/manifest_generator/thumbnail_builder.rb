# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      # Builder for IIIF thumbnail structures
      class ThumbnailBuilder
        attr_reader :asset

        def initialize(asset)
          @asset = asset
        end

        # Build thumbnail structure for manifest
        #
        # @return [Hash] IIIF thumbnail structure
        def build
          {
            'id' => thumbnail_image_url,
            'type' => 'Image',
            'format' => 'image/jpeg',
            'service' => [thumbnail_service]
          }
        end

        private

        # Get the thumbnail image URL with size constraints
        #
        # @return [String] thumbnail image URL
        def thumbnail_image_url
          "#{iiif_image_url}/full/!200,200/0/default.jpg"
        end

        # Build thumbnail service structure
        #
        # @return [Hash] IIIF image service structure
        def thumbnail_service
          {
            'id' => iiif_image_url,
            'type' => 'ImageService3',
            'profile' => 'level2'
          }
        end

        # URL to image in IIIF Image service
        #
        # @return [String] IIIF image service URL
        def iiif_image_url
          raise "#{asset.original_filename} is missing IIIF image" unless asset.iiif_image

          URI.join(Settings.image_server.url, "iiif/3/#{asset.id}").to_s
        end
      end
    end
  end
end
