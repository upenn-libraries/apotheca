# frozen_string_literal: true

module DerivativeService
  # Wrap FFMpeg functionality so it can be used for audio and video generators
  class FfmpegWrapper
    FFMPEG_EXECUTABLE = 'ffmpeg'
    FFPROBE_EXCECUTABLE = 'ffprobe'
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
    VIDEO_LENGTH_OPTIONS = [
      '-loglevel error', # show only errors
      '-of csv=p=0', # set output format to comma-separated values
      '-show_entries format=duration' # show only duration from metadata
    ].freeze
    THUMBNAIL_OPTIONS = [
      '-vframes 1', # extract 1 frame
      '-q:v 2', # set the quality of the output video frame
      '-f image2', # force output as image
      'pipe:1', # output data to stdout
      '-loglevel quiet' # used to suppress ffmpeg console output
    ].freeze

    def self.command(excecutable:, arguments:)
      stdout, stderr, status = Open3.capture3("#{excecutable} #{arguments.join(' ')}")
      raise "FFMpeg Error: #{stderr}" unless status.success?

      stdout
    end

    def self.ffmpeg(input_path:, options:, output_path: nil, input_options: [])
      options = input_options + ["-i #{input_path}"] + options
      options = options + [output_path] if output_path

      command(excecutable: FFMPEG_EXECUTABLE, arguments: options)
    end

    def self.ffprobe(input_path:, options:)
      options = options + [input_path]

      command(excecutable: FFPROBE_EXCECUTABLE, arguments: options)
    end

    def self.video_length(input_path:)
      ffprobe(input_path: input_path, options: VIDEO_LENGTH_OPTIONS)
    end

    def self.thumbnail(input_path:)
      length = video_length(input_path: input_path)
      ffmpeg(input_path: input_path, options: THUMBNAIL_OPTIONS, input_options: ["-ss #{length.to_f / 4}"])
    end

    def self.wav_to_mp3(input_path:, output_path:)
      ffmpeg(input_path: input_path, options: MP3_OPTIONS, output_path: output_path)
      true
    end

    def self.mov_to_mp4(input_path:, output_path:)
      ffmpeg(input_path: input_path, options: MOV_OPTIONS, output_path: output_path)
      true
    end
  end
end
