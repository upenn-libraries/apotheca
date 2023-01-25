# frozen_string_literal: true

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

      # @return [NilClass]
      def thumbnail
        video = file.disk_path
        thumbnail_command = "ffmpeg -i #{video} -ss 00:00:00 -vframes 1 -q:v 2 -f image2 pipe:1 -loglevel quiet"
        output, status = Open3.capture2(thumbnail_command)

        if status.success?
          image = Vips::Image.new_from_buffer(output, '')
          image = image.autorot.thumbnail_image(200, height: 200)

          derivative_file = DerivativeFile.new mime_type: 'image/jpeg'
          image.jpegsave(derivative_file.path, Q: 90, strip: true)
          derivative_file
        else
          raise "Error generating video thumbnail: #{output}"
        end
      rescue => e
        raise Generator::Error, "Error generating video thumbnail: #{e.class} #{e.message}", e.backtrace
      end
    end

    # wrap up ffmpeg interaction
    class FfmpegWrapper
      MOV_OPTIONS = [
        '-y',
        '-vcodec h264', # video codec
        '-acodec mp2', # audio codec
      ].freeze
      FFMPEG_EXECUTABLE = 'ffmpeg'

      # @param [String] input_file_path
      # @param [String] output_file_path
      def self.mov_to_mp4(input_file_path:, output_file_path:)
        # ffmpeg -i my-video.mov -vcodec h264 -acodec mp2 my-video.mp4
        _stdout, stderr, status = Open3.capture3(
          "#{FFMPEG_EXECUTABLE} -i #{input_file_path} #{MOV_OPTIONS.join(' ')} #{output_file_path}"
        )
        raise "FFMpeg Error: #{stderr}" unless status.success?

        true
      end
    end
  end
end
