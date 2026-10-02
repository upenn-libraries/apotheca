# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      class V3
        # Builds IIIF Presentation v3 Canvas representing an Asset.
        class CanvasBuilder
          PLACEHOLDER_WIDTH = 640

          attr_reader :asset, :index

          # Initializes a new Canvas builder
          #
          # @param asset [Object] The asset to build a canvas for
          # @param index [Integer] position/index of the canvas in context
          def initialize(asset, index)
            @asset = asset
            @index = index
          end

          # Build a complete canvas with annotations, placeholder canvas, and rendering.
          #
          # @return [IIIF::V3::Presentation::Canvas] configured canvas
          def build
            canvas = canvas(
              id: "#{base_id}/canvas",
              width: asset.technical_metadata.width,
              height: asset.technical_metadata.height
            )
            canvas['placeholderCanvas'] = placeholder_canvas
            canvas['rendering'] = [download_original_file]
            canvas
          end

          private

          # Create canvas with an annotation page containing one image annotation that paints the image onto the canvas.
          #
          # @param id [String] canvas id, uri
          # @param height [Integer] image height
          # @param width [Integer] image width
          # @param resource_size [String] image size returned in the IIIF image API links
          # @return [IIIF::V3::Presentation::Canvas] canvas with an image annotation
          def canvas(id:, height:, width:, resource_size: '!200,200')
            IIIF::V3::Presentation::Canvas.new('id' => id).tap do |c|
              c.label = label
              c.height = height
              c.width = width
              c.items << IIIF::V3::Presentation::AnnotationPage.new('id' => "#{id}/annotation-page/1").tap do |a|
                a.items << IIIF::V3::Presentation::Annotation.new(
                  'id' => "#{id}/annotation/1",
                  'motivation' => 'painting',
                  'target' => id,
                  'body' => image_resource(width: width, height: height, resource_size: resource_size)
                )
              end
            end
          end

          # Build placeholder canvas for pre-viewer load image preview
          #
          # @return [IIIF::V3::Presentation::Canvas] placeholder canvas
          def placeholder_canvas
            canvas(
              id: "#{base_id}/canvas/placeholder",
              height: placeholder_height,
              width: PLACEHOLDER_WIDTH,
              resource_size: '640,'
            )
          end

          # Calculate scaled height for placeholder image
          #
          # @return [Integer] scaled height
          def placeholder_height
            (asset.technical_metadata.height * PLACEHOLDER_WIDTH / asset.technical_metadata.width).round
          end

          # Create the IIIF image resource
          #
          # @param height [Integer] image height
          # @param width [Integer] image width
          # @param resource_size [String] image size returned in the IIIF image API links
          # @return [IIIF::V3::Presentation::ImageResource] configured image resource
          def image_resource(height:, width:, resource_size: '!200,200')
            image_resource = IIIF::V3::Presentation::ImageResource.create_image_api_image_resource(
              service_id: iiif_image_url,
              resource_id: "#{iiif_image_url}/full/#{resource_size}/0/default.jpg",
              width: width,
              height: height,
              profile: 'level2'
            )
            # Manually set the type of service, this SHOULD be done in the `iiif-presentation` gem
            image_resource.service.first.type = 'ImageService3'
            image_resource
          end

          # Generate download link for original file
          #
          # @return [Hash] rendering structure for original file download
          def download_original_file
            {
              'id' => "https://#{Settings.api_url}/v1/assets/#{asset.id}/preservation",
              'label' => { 'en' => ["Original File - #{asset.technical_metadata.size.to_fs(:human_size)}"] },
              'type' => 'Image',
              'format' => asset.technical_metadata.mime_type
            }
          end

          # Constructs the base canvas if for the asset
          #
          # @return [String] base id for the asset
          def base_id
            "https://#{Settings.api_url}/iiif/assets/#{asset.id}"
          end

          # Provides a label for the asset
          # @return [Hash] A hash with the label in IIIF presentation format
          def label
            { 'none' => [asset.label || "p. #{index}"] }
          end

          # URL to image in IIIF Image service
          #
          # @return [String] IIIF image service URL
          def iiif_image_url
            raise "#{asset.original_filename} is missing IIIF image" unless asset.iiif_image

            URI.join(Settings.image_server.url, "iiif/3/#{asset.id}").to_s
          end
        end
      end
    end
  end
end
