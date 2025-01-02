# frozen_string_literal: true

require 'open3'

module DerivativeService
  module Asset
    module OCR
      # Extract text from images in various file formats
      class TesseractEngine
        DEFAULT_CONFIG = [
          '-c textonly_pdf=1', # extract text only
          '-c tessedit_page_number=0' # only extract from first page if tiff has second page thumbnail
        ].freeze

        TEXT_FORMAT = 'txt'
        PDF_FORMAT = 'pdf'
        HOCR_FORMAT = 'hocr'
        DEFAULT_FORMATS = [TEXT_FORMAT, PDF_FORMAT, HOCR_FORMAT].freeze

        attr_reader :input_path, :output_path, :language_preparer

        def initialize(language:, viewing_direction:)
          @language = language
          @language_preparer = LanguagePreparer.new(languages: @language, viewing_direction: viewing_direction)
        end

        # @return [Array<File>]
        def ocr(input_path:, output_path:)
          options = [*DEFAULT_CONFIG, language_preparer.argument, *DEFAULT_FORMATS]

          TesseractWrapper.execute_tesseract(input_path: input_path, output_path: output_path, options: options)

          return ocr_files(path: output_path) if text_extracted?(path: output_path)

          cleanup_files(path: output_path)

          []
        end

        # @return [TrueClass, FalseClass]
        def ocrable?
          language_preparer.argument.present?
        end

        private

        # OCR text has been extracted if text output file exists and has positive size
        # @return [TrueClass, FalseClass]
        def text_extracted?(path:)
          path.sub_ext(".#{TEXT_FORMAT}").size?.present?
        end

        # @param path [Pathname] directory path where derivatives are located
        # @return [Array<File>]
        def ocr_files(path:)
          DEFAULT_FORMATS.map { |ext| File.new(path.sub_ext(".#{ext}")) }
        end

        # @param path [Pathname]
        def cleanup_files(path:)
          DEFAULT_FORMATS.each do |ext|
            file_path = path.sub_ext(".#{ext}")
            file_path.unlink if file_path.exist?
          end
        end

        # Ensure language data is fit for a tesseract command
        class LanguagePreparer
          # Include fraktur when language is German, Include both Chinese traditional and Chinese Simplified
          # when language is Chinese
          LANGUAGE_EXPANSIONS = { deu: %w[deu frk], chi: %w[chi_tra chi_sim] }.freeze
          # Chinese, Japanese, and Korean language codes require special consideration because they have 'vertical'
          # versions for text meant to be read in vertical columns from right-to-left.
          CJK_LANGUAGE_CODES = %w[jpn kor chi_tra chi_sim].freeze
          # Viewing direction to signal CJK languages are not meant to be read in vertical columns from right-to-left
          LEFT_TO_RIGHT = 'left-to-right'
          VERTICAL_LANGUAGE_SUFFIX = '_vert'
          def initialize(languages: [], viewing_direction: nil)
            @languages = languages
            @viewing_direction = viewing_direction
          end

          # @return [Array<String>]
          def self.supported_languages
            @supported_languages ||= TesseractWrapper.list_langs.lines(chomp: true).drop(1)
          end

          # @return [Array<String>]
          def prepared_languages
            return [] if @languages.blank?

            @prepared_languages ||= @languages.flat_map { |code| LANGUAGE_EXPANSIONS.fetch(code&.to_sym, [code]) }
                                              .filter_map { |code| prepare_code(code) if supported_language?(code) }
          end

          # @return [String, nil]
          def argument
            return if prepared_languages.blank?

            [TesseractWrapper::LANGUAGE_FLAG, prepared_languages.join('+')].join(' ')
          end

          private

          # @param code [String]
          # @return [String]
          def prepare_code(code)
            cjk_language?(code) ? handle_vertical_suffix(code) : code
          end

          # @param code [String]
          # @return [TrueClass, FalseClass]
          def supported_language?(code)
            self.class.supported_languages.include?(code)
          end

          # Assume cjk material is written in right-to-left vertical columns.
          # Add vertical suffix unless viewing direction is 'left-to-right'
          # @param code [String]
          # @return [String]
          def handle_vertical_suffix(code)
            vertical_suffix = @viewing_direction != LEFT_TO_RIGHT ? VERTICAL_LANGUAGE_SUFFIX : ''

            "#{code}#{vertical_suffix}"
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
end
