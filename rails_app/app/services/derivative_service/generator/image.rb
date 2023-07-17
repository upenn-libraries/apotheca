# frozen_string_literal: true

module DerivativeService
  module Generator
    # Generator class encapsulating image derivative generation logic.
    class Image < Base
      VALID_MIME_TYPES = ['image/tiff'].freeze

      # @return [DerivativeService::Generator::DerivativeFile]
      def thumbnail
        # TODO: We might need to apply `page: 0` if the image file is a tiff. Vips says it defaults to 0 though
        #   but before we have had to specify the page/layer for some tiffs.
        image = Vips::Image.new_from_buffer(file.read, '')
        image = image.autorot.thumbnail_image(200, height: 200)

        derivative_file = DerivativeFile.new mime_type: 'image/jpeg'
        image.jpegsave(derivative_file.path, Q: 90, strip: true)
        derivative_file
      rescue StandardError => e
        raise Generator::Error, "Error generating image thumbnail: #{e.class} #{e.message}", e.backtrace
      end

      def access
        image = Vips::Image.new_from_buffer(file.read, '')
        image = image.autorot

        derivative_file = DerivativeFile.new mime_type: 'image/tiff', iiif: true

        image.tiffsave(
          derivative_file.path,
          tile: true,
          pyramid: true,
          compression: :jpeg,
          tile_width: 256,
          tile_height: 256,
          strip: true
        )

        derivative_file
      rescue StandardError => e
        raise Generator::Error, "Error generating image access copy: #{e.class} #{e.message}", e.backtrace
      end
    end
  end
end
