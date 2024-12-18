# frozen_string_literal: true

module DerivativeService
  module Asset
    # Wrap tesseract-ocr command line tool to extract text from images in various file formats
    class TesseractWrapper
      TESSERACT_EXECUTABLE = 'tesseract'

      LANGUAGE_FLAG = '-l'

      DEFAULT_CONFIG = [
        '-c textonly_pdf=1', # extract text only
        '-c tessedit_page_number=0' # only extract from first page if tiff has second page thumbnail
      ].freeze

      TEXT_FORMAT = 'txt'
      PDF_FORMAT = 'pdf'
      HOCR_FORMAT = 'hocr'
      DEFAULT_FORMATS = [TEXT_FORMAT, PDF_FORMAT, HOCR_FORMAT].freeze

      attr_reader :input_path, :output_path, :language_preparer

      def initialize(input_path:, output_path:, language:, viewing_direction: nil)
        @input_path = input_path
        @output_path = output_path
        @language = language
        @language_preparer = LanguagePreparer.new(languages: @language, viewing_direction: viewing_direction)
      end

      def ocr
        return if @language.blank?

        language_argument = @language_preparer.argument

        return if language_argument.blank?

        options = [*DEFAULT_CONFIG, language_argument, *DEFAULT_FORMATS]

        execute_tesseract(input_path: input_path, output_path: output_path, options: options)
      end

      # OCR text has been extracted if text output file exists and has positive size
      # @return [TrueClass, FalseClass]
      def text_extracted?
        @output_path.sub_ext(".#{TEXT_FORMAT}").size?.present?
      end

      private

      def execute_tesseract(input_path:, output_path:, options: [])
        command = [TESSERACT_EXECUTABLE, input_path, output_path, *options].join(' ')
        _stdout, stderr, status = Open3.capture3(command)
        raise "Tesseract Error: #{stderr}" unless status.success?
      end

      # Ensure language data is fit for a tesseract command
      class LanguagePreparer
        SUPPORTED_LANGUAGES_FILE = 'ocr_languages.txt'
        LANGUAGE_EXPANSIONS = { deu: %w[deu frk], chi: %w[chi-tra chi-sim] }.freeze
        CJK_LANGUAGE_CODES = %w[jpn kor chi-tra chi-sim].freeze
        LEFT_TO_RIGHT = 'left-to-right'
        VERTICAL_LANGUAGE_SUFFIX = '_vert'
        def initialize(languages: [], viewing_direction: nil)
          @languages = languages
          @viewing_direction = viewing_direction
        end

        # @return [Array<String>]
        def self.supported_languages
          @supported_languages ||= File.readlines(Rails.root.join(SUPPORTED_LANGUAGES_FILE), chomp: true)
        end

        def supported_languages
          self.class.supported_languages
        end

        # @return [Array<String>]
        def prepared_languages
          return [] if @languages.blank?

          @prepared_languages ||= @languages.flat_map { |code| LANGUAGE_EXPANSIONS.fetch(code&.to_sym, [code]) }
                                            .filter_map do |code|
                                              next unless supported_language?(code)

                                              prepare_code(code)
                                            end
        end

        # @return [String, nil]
        def argument
          return if prepared_languages.blank?

          [LANGUAGE_FLAG, prepared_languages.join('+')].join(' ')
        end

        private

        # @param code [String]
        # @return [String]
        def prepare_code(code)
          prepared = cjk_language?(code) ? handle_cjk_language(code) : code
          normalize_tessdata_code(prepared)
        end

        # tessdata training files use "_" separators instead of "-"
        # @param code [String]
        # @return [String]
        def normalize_tessdata_code(code)
          code.split('-').join('_')
        end

        # @param code [String]
        # @return [String]
        def handle_cjk_language(code)
          vertical_suffix = @viewing_direction != LEFT_TO_RIGHT ? VERTICAL_LANGUAGE_SUFFIX : ''

          "#{code}#{vertical_suffix}"
        end

        # @param code [String]
        # @return [TrueClass, FalseClass]
        def supported_language?(code)
          supported_languages.include?(code)
        end

        # @param code [String]
        # @return [TrueClass, FalseClass]
        def cjk_language?(code)
          CJK_LANGUAGE_CODES.any? { |c| code.starts_with? c }
        end
      end
    end
  end
end
