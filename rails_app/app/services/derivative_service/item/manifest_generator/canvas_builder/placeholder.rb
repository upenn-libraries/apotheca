# frozen_string_literal: true

require 'iiif/v3/presentation'

# Builder for IIIF Presentation v3 placeholder Canvas objects.
#
# @see DerivativeService::Item::ManifestGenerator::Canvas::Base
module DerivativeService
  module Item
    module ManifestGenerator
      module CanvasBuilder
        # Class to build a placeholder canvas with a scaled image.
        class Placeholder < Base
          DOWNSCALED_WIDTH = 640

          # Build placeholder canvas for pre-viewer load image preview
          #
          # @return [IIIF::V3::Presentation::Canvas] placeholder canvas
          def build
            canvas = create_canvas
            canvas.items << create_annotation_page
            canvas
          end

          private

          # Create the main canvas structure
          #
          # @return [IIIF::V3::Presentation::Canvas] basic canvas object
          def create_canvas
            canvas = IIIF::V3::Presentation::Canvas.new
            canvas['id'] = "#{asset_base_url}/canvas/placeholder"
            canvas.label = label
            canvas.height = scaled_height
            canvas.width = DOWNSCALED_WIDTH
            canvas
          end

          # Create annotation page for placeholder canvas
          #
          # @return [IIIF::V3::Presentation::AnnotationPage] placeholder annotation page
          def create_annotation_page
            annotation_page = IIIF::V3::Presentation::AnnotationPage.new
            annotation_page['id'] = "#{asset_base_url}/canvas/placeholder/annotation-page"
            annotation_page.items << create_image_annotation
            annotation_page
          end

          # Create placeholder annotation with scaled image
          #
          # @return [IIIF::V3::Presentation::Annotation] placeholder annotation
          def create_image_annotation
            annotation = IIIF::V3::Presentation::Annotation.new
            annotation['id'] = "#{asset_base_url}/canvas/placeholder/annotation-page/1"
            annotation['motivation'] = 'painting'
            annotation['target'] = "#{asset_base_url}/canvas/placeholder"
            annotation.body = create_image_resource
            annotation
          end

          # Create scaled image resource for placeholder
          #
          # @return [IIIF::V3::Presentation::ImageResource] placeholder image resource
          def create_image_resource
            image_resource = IIIF::V3::Presentation::ImageResource.create_image_api_image_resource(
              service_id: iiif_image_url,
              resource_id: "#{iiif_image_url}/full/640,/0/default.jpg",
              width: DOWNSCALED_WIDTH,
              height: scaled_height,
              profile: 'level2'
            )
            image_resource.service.first.type = 'ImageService3'
            image_resource
          end

          # Calculate scaled height for placeholder image
          #
          # @return [Integer] scaled height
          def scaled_height
            (asset.technical_metadata.height * DOWNSCALED_WIDTH / asset.technical_metadata.width).round
          end
        end
      end
    end
  end
end
