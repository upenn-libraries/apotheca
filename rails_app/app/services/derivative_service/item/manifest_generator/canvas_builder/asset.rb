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
            canvas = create_canvas(id_suffix: 'canvas',
                                   height: asset.technical_metadata.height,
                                   width: asset.technical_metadata.width)
            image_resource = create_image_resource(height: asset.technical_metadata.height,
                                                   width: asset.technical_metadata.width)
            image_annotation = create_image_annotation(id_suffix: 'annotation/1',
                                                       target_suffix: 'canvas',
                                                       image_resource: image_resource)
            canvas.items << create_annotation_page(id_suffix: 'annotation-page/1',
                                                   image_annotation: image_annotation)
            canvas['placeholderCanvas'] = Placeholder.new(asset, index).build
            canvas['rendering'] = [download_original_file]
            canvas
          end

          private

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
