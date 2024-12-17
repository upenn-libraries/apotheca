# frozen_string_literal: true

require 'open3'

module DerivativeService
  module Asset
    module Generator
      # Generator class encapsulating image derivative generation logic.
      class Image < Base
        VALID_MIME_TYPES = ['image/tiff'].freeze

        # @return [DerivativeService::Generator::DerivativeFile]
        def thumbnail
          # TODO: We might need to apply `page: 0` if the image file is a tiff. Vips says it defaults to 0 though
          #   but before we have had to specify the page/layer for some tiffs.
          image = Vips::Image.new_from_buffer(file.read, '')
          image = image.autorot.thumbnail_image(200, height: 200)

          derivative_file = DerivativeFile.new mime_type: 'image/jpeg'
          image.jpegsave(derivative_file.path, Q: 90, strip: true)
          derivative_file
        rescue StandardError => e
          raise Generator::Error, "Error generating image thumbnail: #{e.class} #{e.message}", e.backtrace
        end

        def access
          image = Vips::Image.new_from_buffer(file.read, '')
          image = image.autorot
          image = image.icc_transform('srgb') # Setting srgb as profile, so colors of derivative match the original.

          derivative_file = DerivativeFile.new mime_type: 'image/tiff', iiif_image: true

          image.tiffsave(
            derivative_file.path,
            tile: true,
            pyramid: true,
            compression: :jpeg,
            tile_width: 256,
            tile_height: 256,
            strip: true
          )

          derivative_file
        rescue StandardError => e
          raise Generator::Error, "Error generating image access copy: #{e.class} #{e.message}", e.backtrace
        end

        # @return [DerivativeService::DerivativeFile, nil]
        def textonly_pdf
          ocr.fetch(:textonly_pdf)
        end

        # @return [DerivativeService::DerivativeFile, nil]
        def text
          ocr.fetch(:text)
        end

        # @return [DerivativeService::DerivativeFile, nil]
        def hocr
          ocr.fetch(:hocr)
        end

        private

        def ocr
          @ocr ||= OCR.new(file: file, language: @asset.ocr_language,
                           engine_options: { viewing_direction: @asset.viewing_direction }).generate
        end

        # Generates OCR derivatives using a given ocr engine
        class OCR
          TYPE_MAP = { textonly_pdf: { mime_type: 'application/pdf', extension: 'pdf' },
                       text: { mime_type: 'text/plain', extension: 'txt' },
                       hocr: { mime_type: 'text/html', extension: 'hocr' } }.freeze

          def initialize(file:, language:, engine_class: TesseractWrapper, engine_options: {})
            @file = file
            @language = language
            @engine_class = engine_class
            @engine_options = engine_options
          end

          # @return [Hash]
          def generate
            return empty_derivatives_hash if @language.blank?

            output_path = Pathname.new("#{Dir.tmpdir}/ocr-derivative-file-#{SecureRandom.uuid}")

            @file.tmp_file(extension: '.tif') do |input_path|
              @engine = initialize_engine(input_path: input_path, output_path: output_path)
              @engine.ocr
            end

            return process_empty_ocr(path: output_path) unless @engine.text_extracted?

            build_derivative_files(path: output_path)
          rescue StandardError => e
            raise Generator::Error, "Error generating ocr derivatives: #{e.class} #{e.message}", e.backtrace
          end

          private

          def initialize_engine(input_path:, output_path:)
            @engine_class.new(input_path: input_path, output_path: output_path, language: @language, **@engine_options)
          end

          # @param path [Pathname] directory path where derivatives are located
          # @return [Hash] mapping extension to AssetDerivatives::DerivativeFile
          def build_derivative_files(path:)
            TYPE_MAP.transform_values do |details|
              file = File.new(path.sub_ext(".#{details[:extension]}"))
              DerivativeFile.new(file: file, **details)
            end
          end

          # @param path [Pathname]
          # @return [Hash]
          def process_empty_ocr(path:)
            cleanup_files(path: path)
            empty_derivatives_hash
          end

          def empty_derivatives_hash
            TYPE_MAP.transform_values { nil }
          end

          # @param path [Pathname]
          # @return [Hash]
          def cleanup_files(path:)
            TYPE_MAP.each do |_k, v|
              file_path = path.sub_ext(".#{v[:extension]}")
              file_path.unlink if file_path.exist?
            end
          end
        end
      end
    end
  end
end
