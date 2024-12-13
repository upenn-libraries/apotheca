# frozen_string_literal: true

module DerivativeService
  module Asset
    # Class used to generate Asset-level derivatives.
    class Derivatives
      attr_reader :asset

      delegate :thumbnail, :access, :textonly_pdf, :text, :hocr, to: :generator

      # @param asset [AssetChangeSet]
      def initialize(asset)
        raise ArgumentError, 'Asset provided must be an AssetChangeSet' unless asset.is_a?(AssetChangeSet)
        raise 'Missing mime type' unless asset.technical_metadata.mime_type

        @asset = asset
      end

      def generator
        @generator ||= create_generator
      end

      # Returns true if derivatives will be generated for the mime_type given.
      def self.generate_for?(mime_type)
        supported_mime_types.include?(mime_type)
      end

      # All the mime types we can generate derivatives for.
      def self.supported_mime_types
        Generator::Image::VALID_MIME_TYPES + Generator::Audio::VALID_MIME_TYPES + Generator::Video::VALID_MIME_TYPES
      end

      private

      # Creates the correct generator for a file and mime type.
      def create_generator
        file = SourceFile.new(asset.preservation_file)
        derivative_generator.new(file, @asset)
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
