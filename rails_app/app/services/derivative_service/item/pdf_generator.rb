# frozen_string_literal: true

module DerivativeService
  module Item
    # Class to generate a PDF for an ItemResource
    class PDFGenerator
      POINTS_PER_INCH = 72.0 # PDF points per inch
      START_COORDINATES = [0, 0].freeze # PDF start coordinates

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

          # In order for the PDF to be sized correctly, the width and height of the page must be calculated
          # in PDF points. Because 72 PDF points equal one inch, we can use the image's DPI (dots per inch)
          # and convert the image width and height to PDF points. Essentially, we need to use the DPI to
          # convert the width and height from pixels to inches and then convert the inches to PDF pixels.
          iw = image.width.to_f * (POINTS_PER_INCH / asset.image_dpi)
          ih = image.height.to_f * (POINTS_PER_INCH / asset.image_dpi)

          page = doc.pages.add(START_COORDINATES + [iw, ih])

          page.canvas.image(image, at: START_COORDINATES, width: iw, height: ih)

          # Overlay OCR text layer, if present
          if (textonly_pdf = asset.textonly_pdf)
            ocr_text = HexaPDF::Document.open(textonly_pdf.disk_path)
            ocr_overlay = doc.import(ocr_text.pages.first.to_form_xobject)
            page.canvas(type: :overlay).xobject(ocr_overlay, at: START_COORDINATES, width: iw, height: ih)
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
