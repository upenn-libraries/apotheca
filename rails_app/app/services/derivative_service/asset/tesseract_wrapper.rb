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

      DEFAULT_FORMATS = %w[txt pdf hocr].freeze

      def initialize(language_preparer:)
        @language_preparer = language_preparer
      end

      def ocr(input_path:, output_path:, format: DEFAULT_FORMATS)
        language_argument = @language_preparer.argument

        return if language_argument.blank?

        options = [*DEFAULT_CONFIG, language_argument, *format]

        execute_tesseract(input_path: input_path, output_path: output_path, options: options)
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
        VERTICAL_LANGUAGES = %w[jpn kor chi-tra chi-sim].freeze
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
          @prepared_languages ||= @languages.select { |lang| supported_languages.include?(lang) }
                                            .flat_map { |lang| transform_languages(lang) }
                                            .map { |lang| handle_vertical_languages(lang) }
        end

        # @return [String, nil]
        def argument
          return if prepared_languages.blank?

          [LANGUAGE_FLAG, prepared_languages.join('+')].join(' ')
        end

        private

        # @param lang_code [String]
        # @return [Array<string>]
        def transform_languages(lang_code)
          case lang_code
          when 'deu' then %w[deu frk]
          when 'chi' then %w[chi_tra chi_sim]
          else [lang_code]
          end
        end

        # @param lang_code [String]
        # @return [String]
        def handle_vertical_languages(lang_code)
          vertical_language?(lang_code) ? "#{lang_code}-vert" : lang_code
        end

        # @param lang_code [String]
        # @return [TrueClass, FalseClass]
        def vertical_language?(lang_code)
          VERTICAL_LANGUAGES.include?(lang_code) && @viewing_direction == 'left-to-right'
        end
      end
    end
  end
end
