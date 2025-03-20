# frozen_string_literal: true

module DerivativeService
  module Item
    # Class used to generate Item-level derivatives.
    class Derivatives
      attr_reader :item

      # @param item [ItemChangeSet]
      def initialize(item)
        raise ArgumentError, 'Item provided must be a ItemChangeSet' unless item.is_a?(ItemChangeSet)

        # Derivatives created from items have to be generated from the resource and not the change set because
        # we fetch additional metadata from Solr instance.
        @item = item.resource
      end

      # Generates V2 IIIF manifest
      #
      # @return [DerivativeService::DerivativeFile] when a manifest was generated
      # @return [NilClass] when a manifest could not be generated
      def iiif_manifest
        IIIFManifestGenerator.new(item).v2_manifest
      end

      # Generates a PDF representation of an Item.
      #
      # @return [DerivativeService::DerivativeFile] when a pdf was generated
      # @return [NilClass] when a pdf could not be generated
      def pdf
        PDFGenerator.new(item).pdf
      end

      # Generates or returns pointer to IIIF-image derivative
      #
      # @return [NilClass] when no preview could be generated for the item
      # @return [DerivativeResource] when preview was already generate for the asset
      # @return [DerivativeService::DerivativeFile] when a preview was generated
      def preview
        PreviewGenerator.new(item).preview
      end
    end
  end
end
