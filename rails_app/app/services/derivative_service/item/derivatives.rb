# frozen_string_literal: true

module DerivativeService
  module Item
    # Class used to generate Item-level derivatives.
    class Derivatives
      attr_reader :item

      # @param item [ItemResource]
      def initialize(item)
        raise ArgumentError, 'Item provided must be a ItemResource' unless item.is_a?(ItemResource)

        @item = item
      end

      # Generates V2 IIIF manifest
      #
      # @return [DerivativeService::DerivativeFile] when a manifest was generated
      # @return [NilClass] when a manifest could not be generated
      def iiif_manifest
        manifest = IIIFManifestGenerator.new(item).v2_manifest
        return if manifest.nil?

        file = DerivativeFile.new(mime_type: 'application/json', iiif_manifest: true)
        file.write(manifest)
        file.rewind
        file
      end
    end
  end
end
