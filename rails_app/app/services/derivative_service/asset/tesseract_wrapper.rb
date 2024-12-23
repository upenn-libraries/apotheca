# frozen_string_literal: true

module DerivativeService
  module Asset
    # Wrap tesseract executable for OCR
    class TesseractWrapper
      TESSERACT_EXECUTABLE = 'tesseract'
      LANGUAGE_FLAG = '-l'
      LIST_LANGS = '--list-langs'

      def self.execute_tesseract(input_path:, output_path:, options: [])
        command = [TESSERACT_EXECUTABLE, input_path, output_path, *options].join(' ')
        _stdout, stderr, status = Open3.capture3(command)
        raise "Tesseract Error: #{stderr}" unless status.success?
      end

      # @return [String]
      def self.list_langs
        command = [TESSERACT_EXECUTABLE, LIST_LANGS].join(' ')
        stdout, stderr, status = Open3.capture3(command)
        raise "Tesseract Error: #{stderr}" unless status.success?

        stdout
      end
    end
  end
end
