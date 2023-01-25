# frozen_string_literal: true

module DerivativeService
  # Wrap FFMpeg functionality so it can be used for audio and video generators
  class FfmpegWrapper
    FFMPEG_EXECUTABLE = 'ffmpeg'
    MOV_OPTIONS = [
      '-y', # automatically overwrite any existing output files
      '-vcodec h264', # video codec
      '-acodec mp2', # audio codec
    ].freeze
    # see: https://ffmpeg.org/ffmpeg.html#toc-Generic-options
    # and: https://trac.ffmpeg.org/wiki/Encode/MP3
    MP3_OPTIONS = [
      '-y', # automatically overwrite any existing output files
      '-qscale:a 5', # quality scale, 0 to 10 - this is roughly 128kbps VBR
      '-map_metadata -1', # strip any metadata
      '-ac 2', # ensure 2-channel (stereo) sound
      '-hide_banner' # hide banner about config/formats from output - remove if debugging
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

    # thumbnail_command = "ffmpeg -i #{video} -ss 00:00:00 -vframes 1 -q:v 2 -f image2 pipe:1 -loglevel quiet"
    def self.first_frame_from_video(input_video_file_path:)
      video = input_video_file_path
      # Use FFMpeg to grab the first frame of the input video and save it to stdout
      # loglevel quiet used because FFmpeg was outputting a bunch of stuff to the console during tests
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
    end
  end
end
