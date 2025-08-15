# frozen_string_literal: true

module DerivativeService
  module Item
    module ManifestGenerator
      # Class to generate a IIIF Manifest for an ItemResource
      class V2
        class MissingDerivative < StandardError; end

        attr_reader :item

        # @param [ItemResource]
        def initialize(item)
          raise ArgumentError, 'IIIF manifest can only be generated for ItemResource' unless item.is_a?(ItemResource)

          @item = item.presenter
        end

        # Returns a IIIF Preservation v2 Manifest only representing images.
        #
        # TODO: Later we could use the IIIF Preservation v3 API to display audio and video assets.
        #
        # @return [NilClass] if no images are present
        # @return [DerivativeFile] file containing iiif v2 manifest json
        def manifest
          return nil unless item.arranged_assets.any?(&:image?)

          manifest = IIIF::Presentation::Manifest.new(
            {
              '@id' => colenda.manifest_url(item.unique_identifier),
              'label' => item.descriptive_metadata.title.pluck(:value).join('; '),
              'attribution' => 'Provided by the University of Pennsylvania Libraries.',
              'viewing_hint' => item.structural_metadata.viewing_hint || 'individuals',
              'viewing_direction' => item.structural_metadata.viewing_direction || 'left-to-right',
              'metadata' => iiif_metadata,
              'thumbnail' => thumbnail
            }
          )

          sequence = IIIF::Presentation::Sequence.new('@id' => "#{item_url}/sequence/normal",
                                                      'label' => 'Current order')
          sequence['rendering'] = [pdf_file] if pdf_file

          item.arranged_assets.select(&:image?).map.with_index do |asset, i|
            raise MissingDerivative, "Derivatives missing for #{asset.original_filename}" unless asset.pyramidal_tiff

            index = i + 1

            # Adding canvas that contains image as an image annotation.
            sequence.canvases << canvas(index: index, asset: asset)

            # Adding table of contents, if label and table of contents entries are provided.
            if asset.annotations&.any?
              manifest.structures << range(
                index: index, label: asset.label || "p. #{index}", annotations: asset.annotations.map(&:text)
              )
            end
          end

          manifest.sequences << sequence

          derivative_file = DerivativeFile.new(mime_type: 'application/json', iiif_manifest: true)
          derivative_file.write(manifest.to_json)
          derivative_file.rewind
          derivative_file
        end

        private

        # Manifest-level thumbnail.
        def thumbnail
          return {} unless item.thumbnail&.pyramidal_tiff

          thumbnail_url = iiif_image_url(item.thumbnail)

          {
            "@id": "#{thumbnail_url}/full/!200,200/0/default.jpg",
            "service": {
              "@context": 'http://iiif.io/api/image/2/context.json',
              "@id": thumbnail_url,
              "profile": 'http://iiif.io/api/image/2/level2.json'
            }
          }
        end

        # Metadata to display in image viewer.
        def iiif_metadata
          metadata = [
            {
              label: 'Available Online',
              value: [colenda.public_item_url(item.unique_identifier)]
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

            metadata << { label: field.to_s.titleize, value: normalized_values }
          end
          metadata
        end

        # Returns canvas with one annotated image. The canvas and image size are the same.
        #
        # @param asset [AssetResource] asset displayed on canvas
        # @param index [Integer] canvas number, used to create identifiers
        def canvas(asset:, index:)
          canvas = IIIF::Presentation::Canvas.new
          canvas['@id'] = item_url + "/canvas/p#{index}"
          canvas.label  = asset.label || "p. #{index}"
          canvas.height = asset.technical_metadata.height
          canvas.width  = asset.technical_metadata.width

          annotation = IIIF::Presentation::Annotation.new

          # By providing width, height and profile, we avoid the IIIF gem fetching the data again.
          annotation.resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
            service_id: iiif_image_url(asset), width: asset.technical_metadata.width,
            height: asset.technical_metadata.height, profile: 'http://iiif.io/api/image/2/level2.json'
          )
          annotation['on'] = canvas['@id']

          canvas.images << annotation

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
            IIIF::Presentation::Range.new(
              '@id' => item_url + "/range/r#{index}-#{subrange_index + 1}",
              'label' => annotation,
              'canvases' => [item_url + "/canvas/p#{index}"]
            )
          end

          IIIF::Presentation::Range.new(
            '@id' => item_url + "/range/r#{index}",
            'label' => label,
            'ranges' => subranges
          )
        end

        def pdf_file
          return unless DerivativeService::Item::PDFGenerator.new(item.object).pdfable?

          {
            '@id' => colenda.pdf_url(item.unique_identifier),
            'label' => 'Download PDF',
            'format' => 'application/pdf'
          }
        end

        def download_original_file(asset)
          {
            '@id' => colenda.original_url(item.unique_identifier, asset.id),
            'label' => "Original File - #{asset.technical_metadata.size.to_fs(:human_size)}",
            'format' => asset.technical_metadata.mime_type
          }
        end

        # URL to image in IIIF Image service.
        #
        # @param [AssetResource] asset
        def iiif_image_url(asset)
          raise "#{asset.original_filename} is missing pyramidal tiff" unless asset.pyramidal_tiff

          identifier = if asset.pyramidal_tiff.access?
                         CGI.escape(asset.pyramidal_tiff.file_id.to_s.split(Valkyrie::Storage::Shrine::PROTOCOL)[1])
                       else
                         asset.id.to_s
                       end
          URI.join(image_server.url, "iiif/2/#{identifier}").to_s
        end

        # Image server configuration.
        def image_server
          Settings.image_server
        end

        def item_url
          @item_url ||= colenda.item_url(item.unique_identifier)
        end

        def colenda
          @colenda ||= PublishingService::Endpoint.colenda
        end
      end
    end
  end
end
