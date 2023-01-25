# frozen_string_literal: true

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
end
