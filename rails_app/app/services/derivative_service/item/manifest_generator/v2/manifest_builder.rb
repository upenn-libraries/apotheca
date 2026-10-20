# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      class V2
        # Builder for IIIF Presentation v2 Manifest structure and metadata
        class ManifestBuilder
          class MissingDerivative < StandardError; end

          attr_reader :item

          # @param [ItemResource]
          def initialize(item)
            @item = item.presenter
          end

          # Returns a IIIF Preservation v2 Manifest only representing images.
          #
          # @return [NilClass] if no images are present
          # @return [DerivativeFile] file containing iiif v2 manifest json
          def build
            validate_asset_derivatives!

            IIIF::Presentation::Manifest.new(
              {
                '@id' => "#{base_uri}/manifest",
                'label' => item.descriptive_metadata.title.pluck(:value).join('; '),
                'attribution' => 'Provided by the University of Pennsylvania Libraries.',
                'viewing_hint' => item.structural_metadata.viewing_hint || 'individuals',
                'viewing_direction' => item.structural_metadata.viewing_direction || 'left-to-right',
                'metadata' => MetadataBuilder.new(item).build,
                'thumbnail' => thumbnail,
                'structures' => ranges,
                'sequences' => [sequence]
              }
            )
          end

          private

          # Validate that assets has required derivatives.
          #
          # @raise [MissingDerivative] if pyramidal derivatives are missing
          # @return [void]
          def validate_asset_derivatives!
            raise MissingDerivative, 'Derivatives Missing.' unless item.iiif_images_present?
          end

          # Return sequence of canvases. Each canvas contains an Asset.
          #
          # @return [IIIF::Presentation::Sequence]
          def sequence
            IIIF::Presentation::Sequence.new('@id' => "#{base_uri}/sequence/normal").tap do |sequence|
              sequence['label'] = 'Current order'
              sequence['rendering'] = [pdf_file] if pdf_file

              sequence.canvases = item.arranged_assets.select(&:image?).map.with_index(1) do |asset, i|
                # Adding canvas that contains image as an image annotation.
                CanvasBuilder.new(index: i, asset: asset).build
              end
            end
          end

          # Creating IIIF ranges for Assets. Only creates a range if the Asset has at least
          # one annotation. This structure is the table of contents that's presented in the viewer.
          #
          # @return [Array<IIIF::Presentation::Range>]
          def ranges
            item.arranged_assets.select(&:image?).flat_map do |asset|
              RangesBuilder.new(asset: asset).build
            end
          end

          # Manifest-level thumbnail.
          def thumbnail
            return {} unless item.thumbnail&.iiif_image

            iiif_api = item.thumbnail.iiif_api(version: 2)

            {
              "@id": iiif_api.image_url(size: '!600,600'),
              "service": {
                "@context": 'http://iiif.io/api/image/2/context.json',
                "@id": iiif_api.base_url,
                "profile": 'http://iiif.io/api/image/2/level2.json'
              }
            }
          end

          # Add PDF download for manifest rendering.
          #
          # @return [Hash]
          def pdf_file
            return unless DerivativeService::Item::PDFGenerator.new(item.object).pdfable?

            {
              '@id' => "https://#{Settings.api_url}/v1/items/#{item.id}/pdf",
              'label' => 'Download PDF',
              'format' => 'application/pdf'
            }
          end

          def base_uri
            "https://#{Settings.api_url}/iiif/2/items/#{item.id}"
          end
        end
      end
    end
  end
end
