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
          @ocr ||= OCR.new(file).generate
        end

        # Generates OCR derivatives
        class OCR
          EXTENSION_MAP = { '.pdf': { mime_type: 'application/pdf', derivative_type: :textonly_pdf },
                            '.txt': { mime_type: 'text/plain', derivative_type: :text },
                            '.hocr': { mime_type: 'text/html', derivative_type: :hocr } }.freeze

          def initialize(file)
            @file = file
            @derivatives_map = {}
          end

          # @return [DerivativeService::Asset::Generator::Image::OCR]
          def generate
            @dir = Dir.mktmpdir
            run_tesseract(output_path: "#{@dir}/")
            @derivatives_map = build_derivative_files(dir: @dir)
            self
          rescue StandardError => e
            raise Generator::Error, "Error generating ocr derivatives: #{e.class} #{e.message}", e.backtrace
          end

          # @param type [Symbol]
          # @return [DerivativeService::DerivativeFile, nil]
          def fetch(type)
            @derivatives_map[type]
          end

          private

          # @param output_path [String] path where tesseract will generate ocr files
          def run_tesseract(output_path:)
            @file.tmp_file(extension: '.tif') do |path|
              TesseractWrapper.ocr(input_path: path, output_path: output_path)
            end
          end

          # @param dir [String] directory path where derivatives are located
          # @return [Hash] mapping extension to AssetDerivatives::DerivativeFile
          def build_derivative_files(dir:)
            derivative_files = {}
            Dir.each_child(dir) do |entry_name|
              mime_type = EXTENSION_MAP[entry_name.to_sym][:mime_type]
              derivative_type = EXTENSION_MAP[entry_name.to_sym][:derivative_type]
              derivative_file = DerivativeFile.new(mime_type: mime_type, extension: entry_name)
              IO.copy_stream("#{dir}/#{entry_name}", derivative_file.path)
              derivative_file.rewind
              derivative_files[derivative_type] = derivative_file
            end
            derivative_files
          end
        end
      end
    end
  end
end
