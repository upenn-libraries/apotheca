# frozen_string_literal: true

require 'iiif/v3/presentation'

module DerivativeService
  module Item
    module ManifestGenerator
      # Builder for IIIF Presentation v3 Range objects (table of contents)
      class RangesBuilder
        attr_reader :asset

        def initialize(asset)
          @asset = asset
        end

        # Build ranges for each annotation on the asset
        #
        # @return [Array<IIIF::V3::Presentation::Range>] array of range objects
        def build
          asset.annotations.map.with_index do |annotation, annotation_index|
            build_range(annotation, annotation_index + 1)
          end
        end

        private

        # Build a single range object
        #
        # @param annotation [Object] annotation object with text
        # @param annotation_index [Integer] 1-based annotation index
        # @return [IIIF::V3::Presentation::Range] configured range object
        def build_range(annotation, annotation_index)
          IIIF::V3::Presentation::Range.new(
            'id' => range_id(annotation_index),
            'label' => { 'none' => [labeled_annotation(annotation.text)] },
            'items' => [range_canvas]
          )
        end

        # Generate range ID
        #
        # @param annotation_index [Integer] 1-based annotation index
        # @return [String] range identifier
        def range_id(annotation_index)
          "https://#{Settings.app_url}/iiif/assets/#{asset.id}/toc/#{annotation_index}"
        end

        # Create canvas reference for range
        #
        # @return [IIIF::V3::Presentation::Canvas] canvas reference
        def range_canvas
          IIIF::V3::Presentation::Canvas.new(
            'id' => "https://#{Settings.app_url}/iiif/assets/#{asset.id}/canvas",
            'label' => { 'none' => [asset.label.to_s] }
          )
        end

        # Append the label to the annotation if it isn't already present
        #
        # @param annotation [String] annotation text
        # @return [String] labeled annotation text
        def labeled_annotation(annotation)
          return annotation if asset.label.blank?
          return annotation if /#{Regexp.escape(asset.label)}\s*\z/.match?(annotation)

          [annotation, asset.label].join ', '
        end
      end
    end
  end
end
