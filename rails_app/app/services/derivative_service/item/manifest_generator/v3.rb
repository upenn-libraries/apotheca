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

        delegate :image_server, to: :Settings

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
          return nil unless image_assets.any?

          manifest = build_manifest
          populate_manifest_content(manifest)
          create_derivative_file(manifest)
        end

        private

        # Get all image assets from the item
        #
        # @return [Array<AssetResource>] filtered list of image assets
        def image_assets
          @image_assets ||= item.arranged_assets.select(&:image?)
        end

        # Build the basic manifest structure
        #
        # @return [IIIF::V3::Presentation::Manifest] configured manifest object
        def build_manifest
          ManifestBuilder.new(item).build
        end

        # Add canvases and structures to the manifest
        #
        # @param manifest [IIIF::V3::Presentation::Manifest] manifest to populate
        # @return [void]
        def populate_manifest_content(manifest)
          image_assets.each.with_index(1) do |asset, index|
            validate_asset_derivatives!(asset)

            manifest.items << CanvasBuilder::Asset.new(asset, index).build
            next unless asset.annotations&.any?

            manifest.structures.concat RangesBuilder.new(asset).build
          end
        end

        # Validate that an asset has required derivatives
        #
        # @param asset [AssetResource] asset to validate
        # @raise [MissingDerivative] if pyramidal derivative is missing
        # @return [void]
        def validate_asset_derivatives!(asset)
          return if asset.pyramidal_tiff

          raise MissingDerivative, "Derivatives missing for #{asset.original_filename}"
        end

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
