# frozen_string_literal: true

require 'open3'

module DerivativeService
  module Generator
    # Generator class encapsulating video derivative generation logic.
    class Video < Base
      VALID_MIME_TYPES = %w[video/quicktime].freeze

      # @return [DerivativeService::Generator::DerivativeFile]
      def access
        derivative_file = DerivativeFile.new mime_type: 'video/mp4', extension: '.mp4'
        FfmpegWrapper.mov_to_mp4(
          input_path: file.disk_path,
          output_path: derivative_file.path
        )
        derivative_file
      rescue StandardError => e
        raise Generator::Error, "Error generating MP3: #{e.class} #{e.message}", e.backtrace
      end

      # @return [DerivativeService::Generator::DerivativeFile]
      def thumbnail
        frame = FfmpegWrapper.first_frame_from_video(input_path: file.disk_path)
        image = Vips::Image.new_from_buffer(frame, '')
        image = image.autorot.thumbnail_image(200, height: 200)

        derivative_file = DerivativeFile.new mime_type: 'image/jpeg'
        image.jpegsave(derivative_file.path, Q: 90, strip: true)
        derivative_file
      rescue StandardError => e
        raise Generator::Error, "Error generating video thumbnail: #{e.class} #{e.message}", e.backtrace
      end
    end
  end
end
