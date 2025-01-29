# frozen_string_literal: true

module DerivativeService
  module Item
    # Class to generate a PDF for an ItemResource
    class PDFGenerator
      POINTS_PER_INCH = 72.0 # PDF points per inch
      START_COORDINATES = [0, 0].freeze # PDF start coordinates (bottom, left)

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
        return false unless item.arranged_assets.present?
        return false unless item.arranged_assets.all?(&:image?)

        true
      end

      private

      # Create Item PDF including OCR (if available), bookmarks and cover page.
      #
      # @todo: Need to create cover page.
      #
      # @param [Array<AssetWrapper>] assets
      # @return [HexaPDF::Document]
      def create_pdf(assets)
        HexaPDF::Document.new.tap do |doc|
          add_pages(doc, assets)   # Adds page for each asset.
          add_outline(doc, assets) # Add labels and annotations to the document outline.
        end
      end

      # Add a page for each asset that includes its image and is overlayed with any available OCR.
      def add_pages(doc, assets)
        assets.each do |asset|
          # Add image to document.
          image = doc.images.add(asset.image.path)

          # In order for the PDF to be sized correctly, the width and height of the page must be calculated
          # in PDF points. Because 72 PDF points equal one inch, we can use the image's DPI (dots per inch)
          # and convert the image width and height to PDF points. Essentially, we need to use the DPI to
          # convert the width and height from pixels to inches and then convert the inches to PDF points.
          iw = image.width.to_f * (POINTS_PER_INCH / asset.image_dpi)
          ih = image.height.to_f * (POINTS_PER_INCH / asset.image_dpi)

          # Add page with calculate width and height.
          page = doc.pages.add(START_COORDINATES + [iw, ih])

          # Layer image onto page.
          page.canvas.image(image, at: START_COORDINATES, width: iw, height: ih)

          next unless asset.textonly_pdf

          # Overlay OCR text layer, if present.
          ocr_text = HexaPDF::Document.open(asset.textonly_pdf.disk_path)
          ocr_overlay = doc.import(ocr_text.pages.first.to_form_xobject)
          page.canvas(type: :overlay).xobject(ocr_overlay, at: START_COORDINATES, width: iw, height: ih)
        end
      end

      # Add labels and annotations for each asset as part of the document outline.
      def add_outline(doc, assets)
        assets.each.with_index do |asset, index|
          doc.outline.add_item(asset.label || (index + 1).to_s, destination: index) do |section|
            asset.annotations.each do |annotation|
              section.add_item(annotation, destination: index)
            end
          end
        end
      end
    end
  end
end
