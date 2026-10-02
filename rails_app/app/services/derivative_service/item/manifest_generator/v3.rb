# frozen_string_literal: true

require 'iiif/v3/presentation'

module DerivativeService
  module Item
    module ManifestGenerator
      # Class to generate a IIIF Manifest for an ItemResource
      class V3
        DEFAULT_VIEWING_HINT = 'individuals'
        DEFAULT_VIEWING_DIRECTION = 'left-to-right'
        API_VERSION = 'v1'

        class MissingDerivative < StandardError; end

        attr_reader :item

        # Initialize the manifest generator
        #
        # @param item [ItemResource] the item resource to generate a manifest for
        # @raise [ArgumentError] if item is not an ItemResource
        def initialize(item)
          raise ArgumentError, 'IIIF manifest can only be generated for ItemResource' unless item.is_a?(ItemResource)

          @item = item.presenter
        end

        # Returns a IIIF Presentation v3 Manifest representing images only
        #
        # @note Currently only supports images. Audio and video support is planned.
        # @return [NilClass] if no images are present
        # @return [DerivativeFile] file containing IIIF v3 manifest JSON
        def manifest
          return nil unless item.arranged_assets.any?(&:image?)

          manifest = ManifestBuilder.new(item).build
          create_derivative_file(manifest)
        end

        private

        # Create a derivative file from the manifest
        #
        # @param manifest [IIIF::V3::Presentation::Manifest] completed manifest
        # @return [DerivativeFile] file ready for storage
        def create_derivative_file(manifest)
          derivative_file = DerivativeFile.new(mime_type: 'application/json', iiif_manifest: true)
          derivative_file.write(manifest.to_json)
          derivative_file.rewind
          derivative_file
        end
      end
    end
  end
end
