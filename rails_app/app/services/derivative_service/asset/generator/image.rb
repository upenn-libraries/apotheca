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
          @ocr ||= OCR.new(file: file, asset: @asset).generate
        end

        # Generates OCR derivatives
        class OCR
          TYPE_MAP = { textonly_pdf: { mime_type: 'application/pdf', extension: 'pdf' },
                       text: { mime_type: 'text/plain', extension: 'txt' },
                       hocr: { mime_type: 'text/html', extension: 'hocr' } }.freeze

          def initialize(file:, asset:, engine: nil)
            @file = file
            @asset = asset
            @engine = engine
          end

          def engine
            @engine ||= TesseractWrapper.new(
              language_preparer: TesseractWrapper::LanguagePreparer.new(languages: @asset.ocr_language,
                                                                        viewing_direction: @asset.viewing_direction)
            )
          end

          # @return [Hash]
          def generate
            path = Pathname.new("#{Dir.tmpdir}/ocr-derivative-file-#{SecureRandom.uuid}")

            run_ocr(output_path: path)

            return process_empty_ocr(path: path) if no_text_extracted?(path: path)

            build_derivative_files(path: path)
          rescue StandardError => e
            raise Generator::Error, "Error generating ocr derivatives: #{e.class} #{e.message}", e.backtrace
          end

          private

          # @param output_path [String] path where ocr engine will generate ocr files
          def run_ocr(output_path:)
            return if @asset.ocr_language.blank?

            @file.tmp_file(extension: '.tif') do |path|
              engine.ocr(input_path: path, output_path: output_path)
            end
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

          # OCR text has not been extracted if text output file does not exist or has zero size
          # @param path [Pathname]
          # @return [TrueClass, FalseClass]
          def no_text_extracted?(path:)
            path.sub_ext(".#{TYPE_MAP[:text][:extension]}").size?.nil?
          end
        end
      end
    end
  end
end
