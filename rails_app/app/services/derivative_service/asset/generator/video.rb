# frozen_string_literal: true

require 'open3'

module DerivativeService
  module Asset
    module Generator
      # Generator class encapsulating video derivative generation logic.
      class Video < Base
        VALID_MIME_TYPES = %w[video/quicktime].freeze

        # @return [DerivativeService::Generator::DerivativeFile]
        def access
          derivative_file = DerivativeFile.new mime_type: 'video/mp4', extension: '.mp4'
          file.rewind
          file.disk_path do |path|
            FfmpegWrapper.mov_to_mp4(input_path: path, output_path: derivative_file.path)
          end

          derivative_file
        rescue StandardError => e
          raise Generator::Error, "Error generating MP4: #{e.class} #{e.message}", e.backtrace
        end

        # @return [DerivativeService::Generator::DerivativeFile]
        def thumbnail
          derivative_file = DerivativeFile.new mime_type: 'image/jpeg'
          file.rewind
          file.disk_path do |path|
            frame = FfmpegWrapper.thumbnail(input_path: path)
            image = Vips::Image.new_from_buffer(frame, '').autorot.thumbnail_image(200, height: 200)
            image.jpegsave(derivative_file.path, Q: 90, strip: true)
          end
          derivative_file
        rescue StandardError => e
          raise Generator::Error, "Error generating video thumbnail: #{e.class} #{e.message}", e.backtrace
        end

        def textonly_pdf
          nil
        end

        def text
          nil
        end

        def hocr
          nil
        end
      end
    end
  end
end
