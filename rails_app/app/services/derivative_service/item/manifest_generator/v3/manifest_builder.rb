# frozen_string_literal: true

require 'iiif/v3/presentation'

module DerivativeService
  module Item
    module ManifestGenerator
      class V3
        # Builder for IIIF Presentation v3 Manifest structure and metadata
        class ManifestBuilder
          attr_reader :item

          def initialize(item)
            @item = item.presenter
          end

          # Build IIIF v3 manifest.
          #
          # @return [IIIF::V3::Presentation::Manifest] configured manifest object
          def build
            validate_asset_derivatives!

            manifest = IIIF::V3::Presentation::Manifest.new(
              {
                '@context' => 'http://iiif.io/api/presentation/3/context.json',
                'id' => "https://#{Settings.api_url}/iiif/items/#{item.id}/manifest",
                'label' => { 'none' => [item.descriptive_metadata.title.pluck(:value).join('; ')] },
                'required_statement' => required_statement,
                'behavior' => [item.structural_metadata.viewing_hint || V3::DEFAULT_VIEWING_HINT],
                'viewing_direction' => item.structural_metadata.viewing_direction || V3::DEFAULT_VIEWING_DIRECTION,
                'metadata' => MetadataBuilder.new(item).build,
                'items' => canvases,
                'structures' => ranges
              }
            )

            manifest.thumbnail << thumbnail if thumbnail.present?
            manifest.rendering << pdf_download if pdf_available?
            manifest
          end

          private

          # Return array of canvases. Each canvas represents an asset.
          #
          # @return [Array<IIIF::V3::Presentation::Canvas>]
          def canvases
            item.arranged_assets.select(&:image?).map.with_index(1) do |asset, index|
              CanvasBuilder.new(asset, index).build
            end
          end

          # Creating IIIF ranges for Assets. Only creates a range if the Asset has at least
          # one annotation. This structure is the table of contents that's presented in the viewer.
          #
          # @return [Array<IIIF::V3::Presentation::Range>]
          def ranges
            item.arranged_assets.select(&:image?).flat_map do |asset|
              RangesBuilder.new(asset).build
            end
          end

          # Required statement for attribution
          #
          # @return [Hash] attribution statement structure
          def required_statement
            {
              'label' => { 'none' => ['Attribution'] },
              'value' => { 'none' => ['Provided by the University of Pennsylvania Libraries.'] }
            }
          end

          # Generate manifest-level thumbnail
          #
          # @return [Hash] IIIF item thumbnail structure
          # @return [Hash] empty hash if no thumbnail available
          def thumbnail
            return {} unless item.thumbnail&.iiif_image

            ThumbnailBuilder.new(item.thumbnail).build
          end

          # Check if PDF download should be available
          #
          # @return [Boolean] whether PDF can be generated
          def pdf_available?
            DerivativeService::Item::PDFGenerator.new(item.object).pdfable?
          end

          # PDF download rendering data
          #
          # @return [Hash]
          def pdf_download
            {
              'id' => "https://#{Settings.api_url}/#{V3::API_VERSION}/items/#{item.id}/pdf",
              'label' => { 'en' => ['Download PDF'] },
              'type' => 'Text',
              'format' => 'application/pdf'
            }
          end

          # Validate that an asset has required derivatives
          #
          # @raise [MissingDerivative] if pyramidal derivatives are missing
          # @return [void]
          def validate_asset_derivatives!
            item.arranged_assets.select(&:image?).each do |asset|
              next if asset.iiif_image

              raise MissingDerivative, "Derivatives missing for #{asset.original_filename}"
            end
          end
        end
      end
    end
  end
end
