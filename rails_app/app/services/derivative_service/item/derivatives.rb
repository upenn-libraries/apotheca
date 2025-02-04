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
    end
  end
end
