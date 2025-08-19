# frozen_string_literal: true

require 'iiif/v3/presentation'

# Builder for IIIF Presentation v3 Canvas objects for main asset images.
#
# @see DerivativeService::Item::ManifestGenerator::Canvas::Base
module DerivativeService
  module Item
    module ManifestGenerator
      module CanvasBuilder
        # Class to build a canvas for an image asset.
        class Asset < Base
          # Build a complete canvas with annotations, placeholder canvas, and rendering.
          #
          # @return [IIIF::V3::Presentation::Canvas] configured canvas
          def build
            canvas = create_canvas
            canvas.items << create_annotation_page
            canvas['placeholderCanvas'] = Placeholder.new(asset, index).build
            canvas['rendering'] = [download_original_file]
            canvas
          end

          private

          # Create the main canvas structure
          #
          # @return [IIIF::V3::Presentation::Canvas] basic canvas object
          def create_canvas
            canvas = IIIF::V3::Presentation::Canvas.new
            canvas['id'] = "#{asset_base_url}/canvas"
            canvas.label = label
            canvas.height = asset.technical_metadata.height
            canvas.width = asset.technical_metadata.width
            canvas
          end

          # Create the annotation page containing the image annotation
          #
          # @return [IIIF::V3::Presentation::AnnotationPage] annotation page with image
          def create_annotation_page
            annotation_page = IIIF::V3::Presentation::AnnotationPage.new
            annotation_page['id'] = "#{asset_base_url}/annotation-page/1"
            annotation_page.items << create_image_annotation
            annotation_page
          end

          # Create the image annotation that paints the image onto the canvas
          #
          # @return [IIIF::V3::Presentation::Annotation] image annotation
          def create_image_annotation
            annotation = IIIF::V3::Presentation::Annotation.new
            annotation['id'] = "#{asset_base_url}/annotation/1"
            annotation['motivation'] = 'painting'
            annotation['target'] = "#{asset_base_url}/canvas"
            annotation.body = create_image_resource
            annotation
          end

          # Create the IIIF image resource
          #
          # @return [IIIF::V3::Presentation::ImageResource] configured image resource
          # TODO: MOVE THIS TO BASE, TAKE WIDTH AND HEIGHT AS ARGS
          def create_image_resource
            image_resource = IIIF::V3::Presentation::ImageResource.create_image_api_image_resource(
              service_id: iiif_image_url,
              width: asset.technical_metadata.width,
              height: asset.technical_metadata.height,
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
              'id' => "https://#{Settings.app_url}/v1/assets/#{asset.id}/preservation",
              'label' => { 'en' => ["Original File - #{asset.technical_metadata.size.to_fs(:human_size)}"] },
              'type' => 'Image',
              'format' => asset.technical_metadata.mime_type
            }
          end
        end
      end
    end
  end
end
