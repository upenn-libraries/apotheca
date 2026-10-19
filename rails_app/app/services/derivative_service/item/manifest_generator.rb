# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      # Class to generate a IIIF V2 Manifest for an ItemResource.
      class V2
        class MissingDerivative < StandardError; end

        attr_reader :item

        # @param [ItemResource]
        def initialize(item)
          raise ArgumentError, 'IIIF manifest can only be generated for ItemResource' unless item.is_a?(ItemResource)

          @item = item
        end

        # Generates manifest and writes it to a file.
        #
        # @return [DerivativeFile] file ready for storage
        def manifest
          return nil unless item.arranged_assets.any?(&:image?)

          manifest = ManifestBuilder.new(item).build

          derivative_file = DerivativeFile.new(mime_type: 'application/json', iiif_manifest: true)
          derivative_file.write(manifest.to_json)
          derivative_file.rewind
          derivative_file
        end
      end
    end
  end
end
