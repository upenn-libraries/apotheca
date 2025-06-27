# frozen_string_literal: true

require 'iiif/v3/presentation'

module DerivativeService
  module Item
    # Class to generate a IIIF Manifest for an ItemResource
    class V3IIIFManifestGenerator
      DEFAULT_VIEWING_HINT = 'individuals'
      DEFAULT_VIEWING_DIRECTION = 'left-to-right'
      API_BASE_URL = 'https://apotheca.library.upenn.edu'
      API_VERSION = 'v1'

      class MissingDerivative < StandardError; end

      attr_reader :item

      delegate :image_server, to: :Settings

      # Initialize the manifest generator
      #
      # @param item [ItemResource] the item resource to generate a manifest for
      # @raise [ArgumentError] if item is not an ItemResource
      def initialize(item)
        raise ArgumentError, 'IIIF manifest can only be generated for ItemResource' unless item.is_a?(ItemResource)

        @item = item.presenter
      end

      # Returns a IIIF Presentation v3 Manifest representing images only
      #
      # @note Currently only supports images. Audio and video support is planned.
      # @return [NilClass] if no images are present
      # @return [DerivativeFile] file containing IIIF v3 manifest JSON
      def manifest
        return nil unless image_assets.any?

        manifest = build_manifest
        add_pdf_download(manifest)
        populate_manifest_content(manifest)
        create_derivative_file(manifest)
      end

      private

      # Get all image assets from the item
      #
      # @return [Array<AssetResource>] filtered list of image assets
      def image_assets
        @image_assets ||= item.arranged_assets.select(&:image?)
      end

      # Build the basic manifest structure
      #
      # @return [IIIF::V3::Presentation::Manifest] configured manifest object
      def build_manifest
        IIIF::V3::Presentation::Manifest.new(manifest_attributes)
      end

      # Core manifest attributes
      #
      # @return [Hash]
      def manifest_attributes
        {
          'id' => "#{API_BASE_URL}/iiif/items/#{item.id}/manifest",
          'label' => { 'none' => [item.descriptive_metadata.title.pluck(:value).join('; ')] },
          'required_statement' => {
            'label' => { 'none' => ['Attribution'] },
            'value' => { 'none' => ['Provided by the University of Pennsylvania Libraries.'] }
          },
          'behavior' => [item.structural_metadata.viewing_hint || DEFAULT_VIEWING_HINT],
          'viewing_direction' => item.structural_metadata.viewing_direction || DEFAULT_VIEWING_DIRECTION,
          'metadata' => iiif_metadata,
          'thumbnail' => [thumbnail]
        }
      end

      # Add canvases and structures to the manifest
      #
      # @param manifest [IIIF::V3::Presentation::Manifest] manifest to populate
      # @return [void]
      def populate_manifest_content(manifest)
        image_assets.each_with_index do |asset, i|
          validate_asset_derivatives!(asset)

          index = i + 1
          manifest.items << canvas(index: index, asset: asset)
          next unless asset.annotations&.any?

          manifest.structures.concat ranges(asset: asset, index: index)
        end
      end

      # Validate that an asset has required derivatives
      #
      # @param asset [AssetResource] asset to validate
      # @raise [MissingDerivative] if access derivative is missing
      # @return [void]
      def validate_asset_derivatives!(asset)
        return if asset.access

        raise MissingDerivative, "Derivatives missing for #{asset.original_filename}"
      end

      # Create a derivative file from the manifest
      #
      # @param manifest [IIIF::V3::Presentation::Manifest] completed manifest
      # @return [DerivativeFile] file ready for storage
      def create_derivative_file(manifest)
        derivative_file = DerivativeFile.new(mime_type: 'application/json', iiif_manifest: true)
        derivative_file.write(manifest.to_json)
        derivative_file.rewind
        derivative_file
      end

      # Generate manifest-level thumbnail
      #
      # @return [Hash] IIIF item thumbnail structure
      # @return [Hash] empty hash if no thumbnail available
      def thumbnail
        return {} unless item.thumbnail&.access

        thumbnail_url = iiif_image_url(item.thumbnail)

        {
          'id' => "#{thumbnail_url}/full/!200,200/0/default.jpg",
          'type' => 'Image',
          'format' => 'image/jpeg',
          'service' => [
            {
              'id' => thumbnail_url,
              'type' => 'ImageService3',
              'profile' => 'level2'
            }
          ]
        }
      end

      # Metadata to display in image viewer.
      def iiif_metadata
        metadata = [
          {
            'label' => { 'none' => ['Available Online'] },
            'value' => { 'none' => [colenda.public_item_url(item.id.to_s)] }
          }
        ]

        ItemResource::DescriptiveMetadata::Fields.all.each do |field|
          values = item.descriptive_metadata.send(field)

          next if values.blank?

          normalized_values = case field
                              when :rights
                                values.pluck(:uri).map(&:to_s)
                              when :name
                                values.map do |v|
                                  roles = v[:role]&.pluck(:value)&.join(', ')
                                  roles.present? ? "#{v[:value]} (#{roles})" : v[:value]
                                end
                              else
                                values.pluck(:value)
                              end

          metadata << {
            'label' => { 'none' => [field.to_s.titleize] },
            'value' => { 'none' => normalized_values }
          }
        end
        metadata
      end

      # Returns canvas with one annotated image. The canvas and image size are the same.
      #
      # @param asset [AssetResource] asset displayed on canvas
      # @param index [Integer] canvas number, used to create identifiers
      def canvas(asset:, index:)
        canvas = IIIF::V3::Presentation::Canvas.new
        asset_base_url = "#{API_BASE_URL}/iiif/assets/#{asset.id}"

        canvas['id'] = "#{asset_base_url}/canvas"
        canvas.label  = { 'none' => [asset.label || "p. #{index}"] }
        canvas.height = asset.technical_metadata.height
        canvas.width  = asset.technical_metadata.width

        annotation_page = IIIF::V3::Presentation::AnnotationPage.new
        annotation_page['id'] = asset_base_url + "/annotation-page/#{index}"

        annotation = IIIF::V3::Presentation::Annotation.new
        annotation['id'] = asset_base_url + "/annotation/#{index}"
        annotation['motivation'] = 'painting'
        annotation['target'] = canvas['id']

        # Create the image body
        annotation.body = IIIF::V3::Presentation::ImageResource.create_image_api_image_resource(
          service_id: iiif_image_url(asset), width: asset.technical_metadata.width,
          height: asset.technical_metadata.height, profile: 'level2'
        )
        # Manually set the type of service, this SHOULD be done in the `iiif-presentation` gem
        annotation.body.service.first.type = 'ImageService3'

        annotation_page.items << annotation

        canvas.items << annotation_page
        canvas['rendering'] = [download_original_file(asset)]

        canvas
      end

      # Get array of ranges for each annotation
      #
      # NOTE: The `items` array here is practically useless - the actual annotation is coming from
      # the `label` property on the Range itself. However, validation of the manifest fails with an
      # empty `items` array on a Range. This is kind of hacky to support top level annotations.
      #
      # @param asset [AssetResource]
      # @param index [Integer]
      # @return [Array<IIIF::V3::Presentation::Range>]
      def ranges(asset:, index:)
        label = asset.label || "p. #{index}"
        asset.annotations.map do |annotation|
          IIIF::V3::Presentation::Range.new(
            'id' => API_BASE_URL + "/iiif/assets/#{asset.id}/annotation/#{annotation.id}",
            'label' => { 'none' => [labeled_annotation(label: label, annotation: annotation.text)] },
            'items' => [IIIF::V3::Presentation::Canvas.new(
              'id' => API_BASE_URL + "/iiif/assets/#{asset.id}/canvas/#{annotation.id}",
              'label' => { 'none' => [label] }
            )]
          )
        end
      end

      # Append the label (something like `1r`) to the end of the annotation if it isn't already present
      #
      # @param label [String]
      # @param annotation [String]
      # @return [String]
      def labeled_annotation(label:, annotation:)
        return annotation if /#{Regexp.escape(label)}\s*\z/.match?(annotation)

        [annotation, label].join ', '
      end

      # Add PDF to manifest rendering if it exists
      #
      # @return [nil]
      def add_pdf_download(manifest)
        return unless DerivativeService::Item::PDFGenerator.new(item.object).pdfable?

        manifest.rendering << {
          'id' => pdf_url,
          'label' => { 'en' => ['Download PDF'] },
          'type' => 'Text',
          'format' => 'application/pdf'
        }
      end

      # Generate download link for original file
      #
      # @param asset [AssetResource] asset to create download link for
      # @return [Hash] rendering structure for original file download
      def download_original_file(asset)
        {
          'id' => original_file_url(asset),
          'label' => { 'en' => ["Original File - #{asset.technical_metadata.size.to_fs(:human_size)}"] },
          'type' => 'Image',
          'format' => asset.technical_metadata.mime_type
        }
      end

      # URL to image in IIIF Image service.
      #
      # @param [AssetResource] asset
      def iiif_image_url(asset)
        raise "#{asset.original_filename} is missing access copy" unless asset.access

        filepath = asset.access.file_id.to_s.split(Valkyrie::Storage::Shrine::PROTOCOL)[1]

        URI.join(image_server.url, "iiif/3/#{CGI.escape(filepath)}").to_s
      end

      # Get the base URL for this item
      #
      # @return [String] item URL used as base for canvas and range IDs
      def item_url
        @item_url ||= "#{API_BASE_URL}/#{API_VERSION}/items/#{item.id}"
      end

      # Get the pdf URL for this item
      #
      # @return [String] pdf url for download
      def pdf_url
        @pdf_url ||= "#{item_url}/pdf"
      end

      # Get the original file URL for this item
      #
      # @return [String] preservation URL
      def original_file_url(asset)
        "#{API_BASE_URL}/#{API_VERSION}/assets/#{asset.id}/preservation"
      end

      # Get the Colenda publishing endpoint configuration
      #
      # @return [PublishingService::Endpoint] Colenda endpoint configuration
      def colenda
        @colenda ||= PublishingService::Endpoint.colenda
      end
    end
  end
end
