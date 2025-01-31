# frozen_string_literal: true

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

          # Setting srgb as profile, so colors of derivative match the original. In some cases, the
          # icc profile is not set on the image, if that's the case we cannot perform an icc profile
          # transformation.
          begin
            image = image.icc_transform('srgb')
          rescue StandardError => e
            Honeybadger.notify(e)
          end

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
          @ocr ||= OCR.new(file: file, engine_options: { type: @asset.ocr_type, language: @asset.ocr_language,
                                                         viewing_direction: @asset.viewing_direction }).generate
        end

        # Generates OCR derivatives using a given ocr engine
        class OCR
          TYPE_MAP = { textonly_pdf: { mime_type: 'application/pdf', extension: 'pdf' },
                       text: { mime_type: 'text/plain', extension: 'txt' },
                       hocr: { mime_type: 'text/html', extension: 'hocr' } }.freeze

          PRINT_MATERIAL = 'printed'
          ALL_ENGINES = [PRINT_MATERIAL].freeze

          def initialize(file:, engine_options: {})
            @file = file
            @engine = create_ocr_engine(engine_options)
          end

          # @return [Hash]
          def generate
            return TYPE_MAP.transform_values { nil } unless @engine.present? && @engine.ocrable?

            output_path = Pathname.new("#{Dir.tmpdir}/ocr-derivative-file-#{SecureRandom.uuid}")

            ocr_files = @file.tmp_file(extension: '.tif') do |input_path|
              @engine.ocr(input_path: input_path, output_path: output_path)
            end

            build_derivative_files(ocr_files: ocr_files)
          rescue StandardError => e
            raise Generator::Error, "Error generating ocr derivatives: #{e.class} #{e.message}", e.backtrace
          end

          private

          # @return [DerivativeService::Asset::OCR::Engine::Base, nil]
          # @param engine_options [Hash]
          def create_ocr_engine(engine_options)
            args = engine_options.except(:type)
            case engine_options[:type]
            when PRINT_MATERIAL
              DerivativeService::Asset::OCR::Engine::Tesseract.new(**args)
            end
          end

          # @param ocr_files [Array]
          # @return [Hash] mapping extension to AssetDerivatives::DerivativeFile
          def build_derivative_files(ocr_files:)
            TYPE_MAP.transform_values do |details|
              file = ocr_files.find { |f| f.path.ends_with?(".#{details[:extension]}") }

              file ? DerivativeFile.new(file: file, **details) : nil
            end
          end
        end
      end
    end
  end
end
