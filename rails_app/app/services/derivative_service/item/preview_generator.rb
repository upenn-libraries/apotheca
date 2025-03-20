# frozen_string_literal: true

module DerivativeService
  module Item
    # Class to generate a preview for an ItemResource
    class PreviewGenerator
      attr_reader :item

      # @param [ItemResource]
      def initialize(item)
        raise ArgumentError, 'Thumbnail can only be generated for ItemResource' unless item.is_a?(ItemResource)

        @item = item
      end

      # Generates preview for Item
      #
      # @return [nil|DerivativeResource|DerivativeService::DerivativeFile]
      def preview
        featured_asset = item.thumbnail

        case featured_asset.technical_metadata.mime_type
        when *DerivativeService::Asset::Generator::Image::VALID_MIME_TYPES
          featured_asset.access # Returns access copy derivative
        when *DerivativeService::Asset::Generator::Video::VALID_MIME_TYPES
          # some logic to generated a video derivative
          video_thumbnail(featured_asset)
        end
      end

      # Generating video thumbnail from video access copy.
      #
      # Note: In the future we could consider returning a clip.
      #
      # @return [DerivativeService::DerivativeFile]
      def video_preview(asset)
        file = Valkyrie::StorageAdapter.find_by id: asset.access.file_id

        derivative_file = DerivativeFile.new mime_type: 'image/tiff', iiif_image: true
        file.rewind
        file.disk_path do |path|
          frame = FfmpegWrapper.thumbnail(input_path: path)

          image = Vips::Image.new_from_buffer(frame, '')

          image.tiffsave(
            derivative_file.path,
            tile: true,
            pyramid: true,
            compression: :jpeg,
            tile_width: 256,
            tile_height: 256,
            strip: true
          )
        end
        derivative_file
      end
    end
  end
end
