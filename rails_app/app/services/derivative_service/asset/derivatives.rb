# frozen_string_literal: true

module DerivativeService
  module Asset
    # Class used to generate Asset-level derivatives.
    class Derivatives
      attr_reader :asset

      delegate :thumbnail, :access, to: :generator

      # @param asset [AssetResource]
      def initialize(asset)
        raise ArgumentError, 'Asset provided must be an AssetResource' unless asset.is_a?(AssetResource)
        raise 'Missing mime type' unless asset.technical_metadata.mime_type

        @asset = asset
      end

      def generator
        @generator ||= create_generator
      end

      private

      # Creates the correct generator for a file and mime type.
      def create_generator
        file = Valkyrie::StorageAdapter.find_by id: asset.preservation_file_id
        derivative_generator.new file
      end

      def derivative_generator
        case asset.technical_metadata.mime_type
        when *Generator::Image::VALID_MIME_TYPES
          Generator::Image
        when *Generator::Audio::VALID_MIME_TYPES
          Generator::Audio
        when *Generator::Video::VALID_MIME_TYPES
          Generator::Video
        else
          Generator::Default
        end
      end
    end
  end
end
