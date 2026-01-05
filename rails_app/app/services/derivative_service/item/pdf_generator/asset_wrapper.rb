# frozen_string_literal: true

module DerivativeService
  module Item
    class PDFGenerator
      # Wrapper for AssetResource that provides additional logic needed for creating a PDF representation of an Item.
      class AssetWrapper
        attr_reader :asset

        DEFAULT_SCALE = 0.5 # Default scale applied to images

        def initialize(asset)
          @asset = asset
        end

        # Calculates the DPI of the scaled derivative image.
        #
        # @return [Integer]
        def image_dpi
          (asset.technical_metadata.dpi * DEFAULT_SCALE).to_i
        end

        # Return scaled asset JPEG derivative.
        #
        # @return [DerivativeFile]
        def image
          @image ||= create_jpg
        end

        # Return text-only PDF (containing OCR), if one is present for the asset.
        #
        # @return [Valkyrie::StorageAdapter::StreamFile]
        def textonly_pdf
          @textonly_pdf ||= load_textonly_pdf
        end

        # Cleans up any opened files.
        def cleanup!
          image&.cleanup!
          textonly_pdf&.close

          @image = nil
          @textonly_pdf = nil
        end

        # @return [String]
        def label
          @label ||= asset.label
        end

        # @return [Array<String>]
        def annotations
          @annotations ||= asset.annotations.map(&:text)
        end

        private

        # Create asset JPEG derivative.
        #
        # @return [DerivativeFile]
        def create_jpg
          # Read in pyramidal tiff.
          file = Valkyrie::StorageAdapter.find_by(id: asset.iiif_image.file_id)

          # Create JPEG image
          image = Vips::Image.new_from_buffer(file.read, '')
          image = image.autorot.thumbnail_image(asset.technical_metadata.width * DEFAULT_SCALE,
                                                height: asset.technical_metadata.height * DEFAULT_SCALE)
          image_derivative = DerivativeFile.new mime_type: 'image/jpeg'
          image.jpegsave(image_derivative.path, strip: true)

          image_derivative
        end

        # Load text-only PDF (containing OCR), if one is present for the asset.
        #
        # @return [Valkyrie::StorageAdapter::StreamFile]
        def load_textonly_pdf
          return if asset.textonly_pdf.blank?

          Valkyrie::StorageAdapter.find_by(id: asset.textonly_pdf.file_id)
        end
      end
    end
  end
end
