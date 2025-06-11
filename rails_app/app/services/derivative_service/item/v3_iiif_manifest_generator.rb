# frozen_string_literal: true

require 'iiif/v3/presentation'

module DerivativeService
  module Item
    # Class to generate a IIIF Manifest for an ItemResource
    class V3IIIFManifestGenerator
      class MissingDerivative < StandardError; end

      attr_reader :item

      # @param [ItemResource]
      def initialize(item)
        raise ArgumentError, 'IIIF manifest can only be generated for ItemResource' unless item.is_a?(ItemResource)

        @item = item.presenter
      end

      # Returns a IIIF Preservation v3 Manifest only representing images.
      #
      # TODO: add support for audio and video
      #
      # @return [NilClass] if no images are present
      # @return [DerivativeFile] file containing iiif v3 manifest json
      def manifest
        return nil unless item.arranged_assets.any?(&:image?)

        manifest = IIIF::V3::Presentation::Manifest.new(
          {
            'id' => colenda.manifest_url(item.unique_identifier),
            'label' => { 'none' => [item.descriptive_metadata.title.pluck(:value).join('; ')] },
            'required_statement' => {
              'label' => { 'none' => ['Attribution'] },
              'value' => { 'none' => ['Provided by the University of Pennsylvania Libraries.'] }
            },
            'behavior' => [item.structural_metadata.viewing_hint || 'individuals'],
            'viewing_direction' => item.structural_metadata.viewing_direction || 'left-to-right',
            'metadata' => iiif_metadata,
            'thumbnail' => [thumbnail]
          }
        )

        manifest['rendering'] = [pdf_file] if pdf_file

        item.arranged_assets.select(&:image?).map.with_index do |asset, i|
          raise MissingDerivative, "Derivatives missing for #{asset.original_filename}" unless asset.access

          index = i + 1
          manifest.items << canvas(index: index, asset: asset)
          if asset.annotations&.any?
            manifest.structures << range(
              index: index, label: asset.label || "p. #{index}", annotations: asset.annotations.map(&:text)
            )
          end
        end

        derivative_file = DerivativeFile.new(mime_type: 'application/json', iiif_manifest: true)
        derivative_file.write(manifest.to_json)
        derivative_file.rewind
        derivative_file
      end

      private

      # Manifest-level thumbnail.
      def thumbnail
        return {} unless item.thumbnail&.access

        thumbnail_url = iiif_image_url(item.thumbnail)

        # TODO: the whole thumbnail thing needs its own evaluation of v3 compliance;
        # this is not a complete implementation, just enough to stop erroring out
        {
          'id' => "#{thumbnail_url}/full/!200,200/0/default.jpg",
          'type' => 'Image',
          'format' => 'image/jpeg',
          'service' => {
            'context' => 'http://iiif.io/api/image/3/context.json',
            'id' => thumbnail_url,
            'profile' => image_server.profile
          }
        }
        # This is the OG v2 hash - v3 will error out with it
        # {
        #   "@id": "#{thumbnail_url}/full/!200,200/0/default.jpg",
        #   "service": {
        #     "@context": 'http://iiif.io/api/image/2/context.json',
        #     "@id": thumbnail_url,
        #     "profile": image_server.profile
        #   }
        # }
      end

      # Metadata to display in image viewer.
      def iiif_metadata
        metadata = [
          {
            'label' => { 'none' => ['Available Online'] },
            'value' => { 'none' => [colenda.public_item_url(item.unique_identifier)] }
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
            'label' => { 'none' => [field.to_s.titleize] },  # Language map
            'value' => { 'none' => normalized_values }       # Language map
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
        canvas['id'] = item_url + "/canvas/p#{index}"
        canvas.label  = { 'none' => [asset.label || "p. #{index}"] }
        canvas.height = asset.technical_metadata.height
        canvas.width  = asset.technical_metadata.width

        annotation_page = IIIF::V3::Presentation::AnnotationPage.new
        annotation_page['id'] = item_url + "/canvas/p#{index}/page/1"

        annotation = IIIF::V3::Presentation::Annotation.new
        annotation['id'] = item_url + "/canvas/p#{index}/annotation/1"
        annotation['motivation'] = 'painting'

        # Create the image body
        annotation.body = IIIF::V3::Presentation::ImageResource.create_image_api_image_resource(
          service_id: iiif_image_url(asset), width: asset.technical_metadata.width,
          height: asset.technical_metadata.height, profile: image_server.profile
        )
        annotation['target'] = canvas['id']

        canvas.items << annotation

        canvas['rendering'] = [download_original_file(asset)]

        canvas
      end

      # Returns range with sub ranges for each annotations entry. Each annotation entry will
      # point to the entire canvas.
      #
      # Note: If at some point coordinates are provided for each annotation entry we can point directly
      # to the coordinates given.
      #
      # @param index [Integer] range number, used to create identifiers
      # @param label [String]
      # @param annotations [Array<String>] list of annotations
      def range(index:, label:, annotations:)
        subranges = annotations.map.with_index do |annotation, subrange_index|
          IIIF::V3::Presentation::Range.new(
            'id' => item_url + "/range/r#{index}-#{subrange_index + 1}",
            'label' => { 'none' => [annotation] },
            'items' => [IIIF::V3::Presentation::Canvas.new(
              'id' => item_url + "/canvas/p#{index}",
              'label' => { 'none' => [annotation] }
            )]
          )
        end

        IIIF::V3::Presentation::Range.new(
          'id' => item_url + "/range/r#{index}",
          'label' => { 'none' => [label] },
          'items' => subranges
        )
      end

      def pdf_file
        return unless DerivativeService::Item::PDFGenerator.new(item.object).pdfable?

        {
          'id' => colenda.pdf_url(item.unique_identifier),
          'label' => { 'none' => ['Download PDF'] },
          'type' => 'Text',
          'format' => 'application/pdf'
        }
      end

      def download_original_file(asset)
        {
          'id' => colenda.original_url(item.unique_identifier, asset.id),
          'label' => { 'none' => ["Original File - #{asset.technical_metadata.size.to_fs(:human_size)}"] },
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

        URI.join(image_server.url, "#{image_server.prefix}/#{CGI.escape(filepath)}").to_s
      end

      # Image server configuration.
      delegate :image_server, to: :Settings

      def item_url
        @item_url ||= colenda.item_url(item.unique_identifier)
      end

      def colenda
        @colenda ||= PublishingService::Endpoint.colenda
      end
    end
  end
end
