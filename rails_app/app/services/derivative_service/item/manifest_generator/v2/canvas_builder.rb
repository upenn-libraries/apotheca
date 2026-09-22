# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      class V2
        # Builds IIIF Presentation v2 Canvas representing an Asset.
        class CanvasBuilder
          attr_reader :asset, :index

          # @param asset [AssetResource] asset displayed on canvas
          # @param index [Integer] canvas number, used to create default label
          def initialize(asset:, index:)
            @asset = asset
            @index = index
          end

          # Returns canvas with one annotated image. The canvas and image size are the same.
          #
          # @return [IIIF::Presentation::Canvas]
          def build
            IIIF::Presentation::Canvas.new.tap do |canvas|
              canvas['@id'] = canvas_id
              canvas.label  = asset.label || "p. #{index}"
              canvas.height = asset.technical_metadata.height
              canvas.width  = asset.technical_metadata.width
              canvas.images << image_annotation
              canvas['rendering'] = [download_original_file]
            end
          end

          private

          # Create annotation that paints the image onto the canvas
          #
          # @return [IIIF::Presentation::Annotation]
          def image_annotation
            IIIF::Presentation::Annotation.new.tap do |annotation|
              # By providing width, height and profile, we avoid the IIIF gem fetching the data again.
              annotation.resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
                service_id: iiif_image_url, width: asset.technical_metadata.width,
                height: asset.technical_metadata.height, profile: 'http://iiif.io/api/image/2/level2.json'
              )
              annotation['on'] = canvas_id
            end
          end

          # Return rendering hash for original file.
          #
          # @return [Hash]
          def download_original_file
            {
              '@id' => "https://#{Settings.api_url}/v1/assets/#{asset.id}/preservation",
              'label' => "Original File - #{asset.technical_metadata.size.to_fs(:human_size)}",
              'format' => asset.technical_metadata.mime_type
            }
          end

          def canvas_id
            "https://#{Settings.api_url}/iiif/2/assets/#{asset.id}/canvas"
          end

          # URL to image in IIIF Image service.
          #
          # @return [String]
          def iiif_image_url
            URI.join(Settings.image_server.url, "iiif/2/#{asset.id}").to_s
          end
        end
      end
    end
  end
end
