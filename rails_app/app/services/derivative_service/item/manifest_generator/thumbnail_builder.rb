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
          "#{iiif_image_url}/full/!600,600/0/default.jpg"
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
          raise "#{asset.original_filename} is missing pyramidal tiff" unless asset.pyramidal_tiff

          identifier = if asset.pyramidal_tiff.access?
                         CGI.escape(asset.pyramidal_tiff.file_id.to_s.split(Valkyrie::Storage::Shrine::PROTOCOL)[1])
                       else
                         asset.id.to_s
                       end
          URI.join(Settings.image_server.url, "iiif/3/#{identifier}").to_s
        end
      end
    end
  end
end
