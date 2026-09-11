# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      class V2
        # Builds IIIF Presentation v2 Ranges containing an Asset's annotations.
        class RangesBuilder
          attr_reader :asset

          # @param asset [AssetResource] asset displayed on canvas
          def initialize(asset:)
            @asset = asset
          end

          # Returns an array of ranges representing each annotations entry. Each annotation entry will
          # point to the entire canvas.
          #
          # @return [Array<IIIF::Presentation::Range>]
          def build
            return [] unless asset.annotations&.any?

            asset.annotations.map(&:text).map.with_index(1) do |annotation, index|
              IIIF::Presentation::Range.new(
                '@id' => "https://#{Settings.api_url}/iiif/2/assets/#{asset.id}/toc/#{index}",
                'label' => annotation,
                'canvases' => ["https://#{Settings.api_url}/iiif/2/assets/#{asset.id}/canvas"]
              )
            end
          end
        end
      end
    end
  end
end
