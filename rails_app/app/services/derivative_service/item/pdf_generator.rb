# frozen_string_literal: true

module DerivativeService
  module Item
    # Class to generate a PDF for an ItemResource
    class PDFGenerator
      attr_reader :item

      # @param [ItemResource]
      def initialize(item)
        raise ArgumentError, 'PDF can only be generated for ItemResource' unless item.is_a?(ItemResource)

        @item = item.presenter
      end

      # Return PDF representation of an Item, if one can be created.
      #
      # The PDF contains:
      #   - a cover page
      #   - all images, in arranged order
      #   - if available images are overlay'ed with the extracted OCR
      #   - labels and annotations for each asset
      #
      # @return [DerivativeFile|NilClass]
      def pdf
        return unless pdfable?

        # Run through all the assets and generate jpg derivatives for each one
        assets_data = item.arranged_assets.map do |asset|
          # DPI is required in order to size the PDF correctly.
          original_dpi = asset.technical_metadata.dpi
          raise "Cannot generate PDF without DPI: #{asset.id} is missing dpi." unless original_dpi

          desired_dpi = original_dpi/2 # Shrink images in half

          {
            jpg: { file: asset_jpg(asset, desired_dpi), dpi: desired_dpi },
            textonly_pdf: { file: asset_textonly_pdf(asset) },
            label: asset.label,
            bookmarks: asset.annotations.map(&:text)
          }
        end

        # Create PDF.
        pdf = create_pdf(assets_data)

        # Create PDF derivative file.
        pdf_derivative = DerivativeFile.new mime_type: 'application/pdf', extension: '.pdf'
        pdf.write(pdf_derivative.path, optimize: true)

        # Delete temporary derivative files.
        # These need to be deleted after the PDF file is written because otherwise they are still being referenced.
        assets_data.each do |asset|
          asset[:jpg][:file].cleanup!
          asset[:textonly_pdf][:file]&.close
        end

        # Return PDF derivative file.
        pdf_derivative
      end

      # Returns true if item meets requirements for generating a PDF.
      # @todo Need to flesh out the requirements for a PDF to be generated.
      def pdfable?
        true
      end

      private

      # Create JPEG derivative for the asset given resized to the desired dpi.
      #
      # @param [AssetResource] asset
      # @param [Integer] desired_dpi of derivative jpg
      # @return [DerivativeFile]
      def asset_jpg(asset, desired_dpi)
        # Read in access derivative.
        file = Valkyrie::StorageAdapter.find_by(id: asset.access.file_id)

        # Scale the image should be resized by.
        scale = desired_dpi.to_f / asset.technical_metadata.dpi.to_f

        # Create JPEG image
        image = Vips::Image.new_from_buffer(file.read, '')
        image = image.autorot.thumbnail_image((asset.technical_metadata.width * scale).to_i, height: (asset.technical_metadata.height.to_f * scale).to_i)
        image_derivative = DerivativeFile.new mime_type: 'image/jpeg'
        image.jpegsave(image_derivative.path, strip: true)

        image_derivative
      end

      # Return text-only PDF (containing OCR), if one is present for the asset.
      #
      # @return [Valkyrie::StorageAdapter::StreamFile]
      def asset_textonly_pdf(asset)
        return if asset.textonly_pdf.blank?

        Valkyrie::StorageAdapter.find_by(id: asset.textonly_pdf.file_id)
      end

      # Create Item PDF including OCR (if available), bookmarks and cover page.
      #
      # @todo: Need to create cover page.
      #
      # @param [Hash] assets_data # TODO:
      # @return [HexaPDF::Document]
      def create_pdf(assets_data)
        doc = HexaPDF::Document.new

        assets_data.each do |data|
          image = doc.images.add(data[:jpg][:file].path)

          iw = image.width.to_f * (72.0 / data[:jpg][:dpi].to_f)
          ih = image.height.to_f * (72.0 / data[:jpg][:dpi].to_f)

          page = doc.pages.add([0, 0, iw, ih])

          page.canvas.image(image, at: [0, 0], width: iw, height: ih)

          # Overlay OCR text layer, if present
          if (textonly_pdf = data[:textonly_pdf][:file])
            ocr_text = HexaPDF::Document.open(textonly_pdf.disk_path)
            ocr_overlay = doc.import(ocr_text.pages.first.to_form_xobject)
            page.canvas.xobject(ocr_overlay, at: [0, 0], width: iw, height: ih)
          end

          # Add bookmarks
          # @todo This only displays bookmarks/outline in Adobe Reader, the bookmarks are not displayed in Preview.
          #  section = doc.outline.add_item(file, destination: page)
        end

        doc
      end
    end
  end
end
