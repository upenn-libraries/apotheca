module IIIFService
  class ManifestGenerator
    class MissingDerivative < StandardError; end

    attr_reader :item

    # @param [ItemResource]
    def initialize(item)
      raise ArgumentError, 'IIIF manifest can only be generated for ItemResource' unless item.is_a?(ItemResource)

      @item = item
    end

    # Returns a IIIF Preservation v2 Manifest only representing images.
    #
    # TODO: Later we could use the IIIF Preservation v3 API to display audio and video assets.
    #
    # @return [NilClass] if no images are present
    # @return [String] iiif v2 manifest json
    def v2_manifest
      return nil unless arranged_assets.any?(&:image?)

      manifest = IIIF::Presentation::Manifest.new({
        '@id' => uri(base_uri, 'manifest'),
        'label' => item.descriptive_metadata.title.map(&:value).join('; '),
        'attribution' => 'Provided by the University of Pennsylvania Libraries.',
        'viewing_hint' => item.structural_metadata.viewing_hint || 'individuals',
        'viewing_direction' => item.structural_metadata.viewing_direction || 'left-to-right'
      })

      sequence = IIIF::Presentation::Sequence.new(
        '@id' => uri(base_uri, 'sequence/normal'),
        'label' => 'Current order'
      )

      arranged_assets.select(&:image?).map.with_index do |asset, i|
        raise MissingDerivative, "Derivatives missing for #{asset.original_filename}" unless asset.access

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
      manifest.to_json
    end

    private

    def arranged_assets
      @arranged_assets ||= item.arranged_assets
    end

    # Returns canvas with one annotated image. The canvas and image size are the same.
    #
    # @param asset [AssetResource] asset displayed on canvas
    # @param index [Integer] canvas number, used to create identifiers
    def canvas(asset:, index:)
      canvas = IIIF::Presentation::Canvas.new
      canvas['@id'] = uri(base_uri, "canvas/p#{index}")
      canvas.label  = asset.label || "p. #{index}"
      canvas.height = asset.technical_metadata.height
      canvas.width  = asset.technical_metadata.width

      annotation = IIIF::Presentation::Annotation.new
      filepath = asset.access.file_id.to_s.split(Valkyrie::Storage::Shrine::PROTOCOL)[1]

      # By providing width, height and profile, we avoid the IIIF gem fetching the data again.
      annotation.resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
        service_id: uri(image_server_url, CGI.escape(filepath)), width: asset.technical_metadata.width,
        height: asset.technical_metadata.height, profile: image_server_profile
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
          '@id' => uri(base_uri, "range/r#{index}-#{subrange_index + 1}"),
          'label' => annotation,
          'canvases' => [uri(base_uri, "canvas/p#{index}")]
        )
      end

      IIIF::Presentation::Range.new(
        '@id' => uri(base_uri, "range/r#{index}"),
        'label' => label,
        'ranges' => subranges
      )
    end

    def iiif_image_url(asset)
      raise "#{asset.original_filename} is missing access copy" unless asset.access?

      uri(image_server_url, filepath)
    end

    # TODO: We could make the asset download path configurable in the future.
    def download_original_file(asset)
      {
        '@id' => uri(base_uri, "assets/#{asset.id}/preservation-file"), # TODO: Add controller in Bulwark/Colenda
        'label' => "Original File - #{asset.technical_metadata.size.to_fs(:human_size)}",
        'format' => asset.technical_metadata.mime_type
      }
    end

    def image_server_url
      Settings.iiif.image_server.url
    end

    # Profile that image server supports.
    def image_server_profile
      Settings.iiif.image_server.profile
    end

    def base_uri
      @base_uri ||= uri(Settings.iiif.manifest.base_url, item.unique_identifier)
    end

    # Helper method to append path to url.
    def uri(base_url, path)
      base_url = "#{base_url}/" unless base_url.end_with?('/') # Add trailing slash to url.
      path = path[1..] if path.starts_with?('/') # Remove starting slash from path.

      base_url + path
    end
  end
end