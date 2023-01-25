# frozen_string_literal: true

# frozen_string_literal: true

require 'open3'

module DerivativeService
  module Generator
    # Generator class encapsulating audio derivative generation logic.
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
        nil
      end
    end

    # wrap up ffmpeg interaction
    class FfmpegWrapper
      # see: https://ffmpeg.org/ffmpeg.html#toc-Generic-options
      # and: https://trac.ffmpeg.org/wiki/Encode/MP3
      MP3_OPTIONS = [
        '-y', # automatically overwrite any existing output files
        '-qscale:a 5', # quality scale, 0 to 10 - this is roughly 128kbps VBR
        '-map_metadata -1', # strip any metadata
        '-ac 2', # ensure 2-channel (stereo) sound
        '-hide_banner' # hide banner about config/formats from output - remove if debugging
      ].freeze
      FFMPEG_EXECUTABLE = 'ffmpeg'

      MOV_OPTIONS = [
        '-y',
        '-vcodec h264', # video codec
        '-acodec mp2', # audio codec
      ].freeze

      # @param [String] input_file_path
      # @param [String] output_file_path
      def self.wav_to_mp3(input_file_path:, output_file_path:)
        _stdout, stderr, status = Open3.capture3(
          "#{FFMPEG_EXECUTABLE} -i #{input_file_path} #{MP3_OPTIONS.join(' ')} #{output_file_path}"
        )
        raise "FFMpeg Error: #{stderr}" unless status.success?

        true
      end

      def self.mov_to_mp4(input_file_path:, output_file_path:)
        # ffmpeg -i my-video.mov -vcodec h264 -acodec mp2 my-video.mp4
        _stdout, stderr, status = Open3.capture3(
          "#{FFMPEG_EXECUTABLE} -i #{input_file_path} #{MOV_OPTIONS.join(' ')} #{output_file_path}"
        )
      end
    end
  end
end
