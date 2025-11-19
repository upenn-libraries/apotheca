# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      module CanvasBuilder
        # Shared behavior for different Canvas builders
        class Base
          attr_reader :asset, :index

          # Initializes a new Canvas builder
          # @param asset [Object] The asset to build a canvas for
          # @param index [Integer] position/index of the canvas in context
          def initialize(asset, index)
            @asset = asset
            @index = index
          end

          # Builds the canvas representation
          # @raise [NotImplementedError] when called on the base class
          def build
            raise NotImplementedError
          end

          protected

          # Create the main canvas structure
          #
          # @param id_suffix [String] end of the canvas ID
          # @param height [Integer] canvas height
          # @param width [Integer] canvas width
          # @return [IIIF::V3::Presentation::Canvas] basic canvas object
          def create_canvas(id_suffix:, height:, width:)
            canvas = IIIF::V3::Presentation::Canvas.new
            canvas['id'] = "#{asset_base_url}/#{id_suffix}"
            canvas.label = label
            canvas.height = height
            canvas.width = width
            canvas
          end

          # Create the annotation page containing the image annotation
          #
          # @param id_suffix [String] end of the annotation page ID
          # @param image_annotation [IIIF::V3::Presentation::Annotation] annotation connecting the image to the canvas
          # @return [IIIF::V3::Presentation::AnnotationPage] annotation page with image
          def create_annotation_page(id_suffix:, image_annotation:)
            annotation_page = IIIF::V3::Presentation::AnnotationPage.new
            annotation_page['id'] = "#{asset_base_url}/#{id_suffix}"
            annotation_page.items << image_annotation
            annotation_page
          end

          # Create the image annotation that paints the image onto the canvas
          #
          # @param id_suffix [String] end of the annotation ID
          # @param target_suffix [String] end of the target ID
          # @param image_resource [IIIF::V3::Presentation::ImageResource] annotation body
          # @return [IIIF::V3::Presentation::Annotation] image annotation
          def create_image_annotation(id_suffix:, target_suffix:, image_resource:)
            annotation = IIIF::V3::Presentation::Annotation.new
            annotation['id'] = "#{asset_base_url}/#{id_suffix}"
            annotation['motivation'] = 'painting'
            annotation['target'] = "#{asset_base_url}/#{target_suffix}"
            annotation.body = image_resource
            annotation
          end

          # Create the IIIF image resource
          #
          # @param height [Integer] image height
          # @param width [Integer] image width
          # @param resource_size [String] how the IIIF image API should process the resource
          # @return [IIIF::V3::Presentation::ImageResource] configured image resource
          def create_image_resource(height:, width:, resource_size: '!200,200')
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

          # Constructs the base iiif URL for the asset
          # @return [String] The IIIF base URL for the asset
          def asset_base_url
            "https://#{Settings.app_url}/iiif/assets/#{asset.id}"
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
