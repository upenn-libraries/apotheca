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
          input_file_path: file.disk_path,
          output_file_path: derivative_file.path
        )
        derivative_file
      rescue StandardError => e
        raise Generator::Error, "Error generating MP3: #{e.class} #{e.message}", e.backtrace
      end

      # @return [DerivativeService::Generator::DerivativeFile]
      def thumbnail
        FfmpegWrapper.first_frame_from_video(input_video_file_path: file.disk_path)
      rescue StandardError => e
        raise Generator::Error, "Error generating video thumbnail: #{e.class} #{e.message}", e.backtrace
      end
    end
  end
end
