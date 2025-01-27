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

        # Wrap all assets with AssetWrapper class.
        assets = item.arranged_assets.map { |a| AssetWrapper.new(a) }

        # Create PDF.
        pdf = create_pdf(assets)

        # Create PDF derivative file.
        pdf_derivative = DerivativeFile.new mime_type: 'application/pdf', extension: '.pdf'
        pdf.write(pdf_derivative.path, optimize: true)

        # Cleanup temporary derivative files.
        # These need to be deleted after the PDF file is written because otherwise they are still being referenced.
        assets.each(&:cleanup!)

        # Return PDF derivative file.
        pdf_derivative
      end

      # Returns true if item meets requirements for generating a PDF.
      # @todo Need to flesh out the requirements for a PDF to be generated.
      def pdfable?
        true
      end

      private

      # Create Item PDF including OCR (if available), bookmarks and cover page.
      #
      # @todo: Need to create cover page.
      #
      # @param [Array<AssetWrapper>] assets # TODO:
      # @return [HexaPDF::Document]
      def create_pdf(assets)
        doc = HexaPDF::Document.new

        assets.each do |asset|
          image = doc.images.add(asset.image.path)

          iw = image.width.to_f * (72.0 / asset.image_dpi)
          ih = image.height.to_f * (72.0 / asset.image_dpi)

          page = doc.pages.add([0, 0, iw, ih])

          page.canvas.image(image, at: [0, 0], width: iw, height: ih)

          # Overlay OCR text layer, if present
          if (textonly_pdf = asset.textonly_pdf)
            ocr_text = HexaPDF::Document.open(textonly_pdf.disk_path)
            ocr_overlay = doc.import(ocr_text.pages.first.to_form_xobject)
            page.canvas(type: :overlay).xobject(ocr_overlay, at: [0, 0], width: iw, height: ih)
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
