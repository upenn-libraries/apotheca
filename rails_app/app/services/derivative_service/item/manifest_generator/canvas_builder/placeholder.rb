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
            canvas = create_canvas(id_suffix: 'canvas/placeholder',
                                   height: scaled_height,
                                   width: DOWNSCALED_WIDTH)
            image_resource = create_image_resource(height: scaled_height,
                                                   width: DOWNSCALED_WIDTH, resource_size: '640,')
            image_annotation = create_image_annotation(id_suffix: 'canvas/placeholder/annotation-page/1',
                                                       target_suffix: 'canvas/placeholder',
                                                       image_resource: image_resource)
            canvas.items << create_annotation_page(id_suffix: 'canvas/placeholder/annotation-page',
                                                   image_annotation: image_annotation)
            canvas
          end

          private

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
