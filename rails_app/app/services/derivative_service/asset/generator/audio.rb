# frozen_string_literal: true

require 'open3'

module DerivativeService
  module Asset
    module Generator
      # Generator class encapsulating audio derivative generation logic.
      class Audio < Base
        VALID_MIME_TYPES = %w[audio/wav audio/wave audio/x-wav audio/x-wave audio/x-pn-wav audio/vnd.wave].freeze

        # @return [DerivativeService::Generator::DerivativeFile]
        def access
          derivative_file = DerivativeFile.new mime_type: 'audio/mpeg', extension: '.mp3'
          file.tmp_file do |path|
            FfmpegWrapper.wav_to_mp3(input_path: path, output_path: derivative_file.path)
          end

          derivative_file
        rescue StandardError => e
          raise Generator::Error, "Error generating MP3: #{e.class} #{e.message}", e.backtrace
        end

        # @return [NilClass]
        def thumbnail
          nil
        end
      end
    end
  end
end
