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
            raise "#{asset.original_filename} is missing pyramidal tiff" unless asset.pyramidal_tiff

            identifier = if asset.pyramidal_tiff.access?
                           CGI.escape(asset.pyramidal_tiff.file_id.to_s.split(Valkyrie::Storage::Shrine::PROTOCOL)[1])
                         else
                           asset.id.to_s
                         end
            URI.join(Settings.image_server.url, "iiif/3/#{identifier}").to_s
          end
        end
      end
    end
  end
end
