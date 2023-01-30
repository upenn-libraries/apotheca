# frozen_string_literal: true

module DerivativeService
  # Wrap FFMpeg functionality so it can be used for audio and video generators
  class FfmpegWrapper
    FFMPEG_EXECUTABLE = 'ffmpeg'
    MOV_OPTIONS = [
      '-y', # automatically overwrite any existing output files
      '-vcodec h264', # video codec h264
      '-acodec aac' # audio codec aac
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
    FIRST_FRAME_OPTIONS = [
      '-ss 00:00:00', # seek to a specific time in the input file
      '-vframes 1', # extract a specific number of video frames
      '-q:v 2', # set the quality of the output video frame
      '-f image2', # force output as image
      'pipe:1', # output data to stdout
      '-loglevel quiet' # used to suppress ffmpeg console output
    ].freeze

    # @param [String] input_path
    # @param [Array] options
    # @param [String] output_path
    # @return [String] stdout
    def self.command(input_path:, options:, output_path: nil)
      command_string = "#{FFMPEG_EXECUTABLE} -i #{input_path} #{options.join(' ')}"
      command_string += " #{output_path}" if output_path

      stdout, stderr, status = Open3.capture3(command_string)
      raise "FFMpeg Error: #{stderr}" unless status.success?

      stdout
    end

    def self.wav_to_mp3(input_path:, output_path:)
      command(input_path: input_path, options: MP3_OPTIONS, output_path: output_path)
      true
    end

    def self.mov_to_mp4(input_path:, output_path:)
      command(input_path: input_path, options: MOV_OPTIONS, output_path: output_path)
      true
    end

    def self.first_frame_from_video(input_path:)
      command(input_path: input_path, options: FIRST_FRAME_OPTIONS)
    end
  end
end
