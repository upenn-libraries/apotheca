# frozen_string_literal: true

module DerivativeService
  module Generator
    # Generator class encapsulating image derivative generation logic.
    class Image < Base
      VALID_MIME_TYPES = ['image/tiff', 'image/jpeg'].freeze

      # @return [DerivativeService::Generator::DerivativeFile]
      def thumbnail
        # TODO: i think we need to apply page: 0 if its a tiff, vips says it defaults to 0 though
        # but in bulwark we had to specify the page number for some tiffs
        image = Vips::Image.new_from_buffer(file.read, '')
        image = image.autorot.thumbnail_image(200, height: 200)

        derivative_file = DerivativeFile.new('image/jpeg')
        image.jpegsave(derivative_file.path, Q: 90, strip: true)
        derivative_file
      end

      def access
        image = Vips::Image.new_from_buffer(file.read, '')
        image = image.autorot

        derivative_file = DerivativeFile.new('image/tiff')

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
      end

      def thumbnail?
        true
      end

      def access?
        true
      end
    end
  end
end
