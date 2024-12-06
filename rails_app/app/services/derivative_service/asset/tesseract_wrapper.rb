# frozen_string_literal: true

module DerivativeService
  module Asset
    # Wrap tesseract-ocr command line tool to generate hOCR and pdfs from image files
    class TesseractWrapper
      TESSERACT_EXECUTABLE = 'tesseract'

      # @todo pass in languages dynamically from existing resource data
      LANGUAGE_OPTIONS = ['-l eng'].freeze

      OCR_OPTIONS = [
        '-c textonly_pdf=1', # extract text only
        '-c tessedit_page_number=0' # only extract from first page if tiff has second page thumbnail
      ].freeze

      HOCR_FORMAT = 'hocr'
      PDF_FORMAT = 'pdf'
      TXT_FORMAT = 'txt'

      def self.command(executable:, arguments: [])
        _stdout, stderr, status = Open3.capture3("#{executable} #{arguments.join(' ')}")
        raise "Tesseract Error: #{stderr}" unless status.success?
      end

      def self.tesseract(input_path:, output_path:, options: [])
        arguments = [input_path] + [output_path] + options
        command(executable: TESSERACT_EXECUTABLE, arguments: arguments)
      end

      def self.ocr(input_path:, output_path:, _languages: [])
        options = OCR_OPTIONS + LANGUAGE_OPTIONS + [PDF_FORMAT] + [TXT_FORMAT] + [HOCR_FORMAT]
        tesseract(input_path: input_path, output_path: output_path, options: options)
      end
    end
  end
end
