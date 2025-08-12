# frozen_string_literal: true

require 'iiif/v3/presentation'

module DerivativeService
  module Item
    module ManifestGenerator
      # Builder for IIIF Presentation v3 Canvas objects
      class CanvasBuilder
        attr_reader :asset, :index

        def initialize(asset, index)
          @asset = asset
          @index = index
        end

        # Build a complete canvas with annotations and placeholder
        #
        # @return [IIIF::V3::Presentation::Canvas] configured canvas
        def build
          canvas = create_canvas
          canvas.items << create_annotation_page
          canvas['placeholderCanvas'] = create_placeholder_canvas
          canvas['rendering'] = [download_original_file]
          canvas
        end

        private

        # Create the main canvas structure
        #
        # @return [IIIF::V3::Presentation::Canvas] basic canvas object
        def create_canvas
          canvas = IIIF::V3::Presentation::Canvas.new
          canvas['id'] = canvas_id
          canvas.label = { 'none' => [asset.label || "p. #{index}"] }
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
          annotation['target'] = canvas_id
          annotation.body = create_image_resource
          annotation
        end

        # Create the IIIF image resource
        #
        # @return [IIIF::V3::Presentation::ImageResource] configured image resource
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

        # Create placeholder canvas for pre-viewer load image preview
        #
        # @return [IIIF::V3::Presentation::Canvas] placeholder canvas
        def create_placeholder_canvas
          placeholder_canvas = IIIF::V3::Presentation::Canvas.new
          placeholder_canvas['id'] = "#{asset_base_url}/canvas/placeholder"
          placeholder_canvas.label = { 'none' => [asset.label || "p. #{index}"] }
          placeholder_canvas.items << create_placeholder_annotation_page
          placeholder_canvas
        end

        # Create annotation page for placeholder canvas
        #
        # @return [IIIF::V3::Presentation::AnnotationPage] placeholder annotation page
        def create_placeholder_annotation_page
          annotation_page = IIIF::V3::Presentation::AnnotationPage.new
          annotation_page['id'] = "#{asset_base_url}/canvas/placeholder/annotation-page"
          annotation_page.items << create_placeholder_annotation
          annotation_page
        end

        # Create placeholder annotation with scaled image
        #
        # @return [IIIF::V3::Presentation::Annotation] placeholder annotation
        def create_placeholder_annotation
          annotation = IIIF::V3::Presentation::Annotation.new
          annotation['id'] = "#{asset_base_url}/canvas/placeholder/annotation-page/1"
          annotation['motivation'] = 'painting'
          annotation['target'] = "#{asset_base_url}/canvas/placeholder"
          annotation.body = create_placeholder_image_resource
          annotation
        end

        # Create scaled image resource for placeholder
        #
        # @return [IIIF::V3::Presentation::ImageResource] placeholder image resource
        def create_placeholder_image_resource
          image_resource = IIIF::V3::Presentation::ImageResource.create_image_api_image_resource(
            service_id: iiif_image_url,
            resource_id: "#{iiif_image_url}/full/640,/0/default.jpg",
            width: asset.technical_metadata.width,
            height: asset.technical_metadata.height,
            profile: 'level2'
          )
          image_resource.service.first.type = 'ImageService3'
          image_resource
        end

        # Generate download link for original file
        #
        # @return [Hash] rendering structure for original file download
        def download_original_file
          {
            'id' => original_file_url,
            'label' => { 'en' => ["Original File - #{asset.technical_metadata.size.to_fs(:human_size)}"] },
            'type' => 'Image',
            'format' => asset.technical_metadata.mime_type
          }
        end

        # Get the canvas ID
        #
        # @return [String] canvas identifier
        def canvas_id
          "#{asset_base_url}/canvas"
        end

        # Get the asset base URL
        #
        # @return [String] base URL for asset resources
        def asset_base_url
          "https://#{Settings.app_url}/iiif/assets/#{asset.id}"
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

        # Get the original file URL for this asset
        #
        # @return [String] preservation URL
        def original_file_url
          "https://#{Settings.app_url}/#{V3::API_VERSION}/assets/#{asset.id}/preservation"
        end
      end
    end
  end
end
