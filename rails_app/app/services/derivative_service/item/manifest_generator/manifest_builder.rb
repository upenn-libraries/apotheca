# frozen_string_literal: true

require 'iiif/v3/presentation'

module DerivativeService
  module Item
    module ManifestGenerator
      # Builder for IIIF Presentation v3 Manifest structure and metadata
      class ManifestBuilder
        attr_reader :item

        def initialize(item)
          @item = item
        end

        # Build and configure the manifest with core attributes
        #
        # @return [IIIF::V3::Presentation::Manifest] configured manifest object
        def build
          manifest = IIIF::V3::Presentation::Manifest.new(manifest_attributes)
          add_pdf_download(manifest) if pdf_available?
          manifest
        end

        private

        # Core manifest attributes
        #
        # @return [Hash] manifest configuration hash
        def manifest_attributes
          hash = {
            'id' => "https://#{Settings.app_url}/iiif/items/#{item.id}/manifest",
            'label' => { 'none' => [item.descriptive_metadata.title.pluck(:value).join('; ')] },
            'required_statement' => required_statement,
            'behavior' => [item.structural_metadata.viewing_hint || V3::DEFAULT_VIEWING_HINT],
            'viewing_direction' => item.structural_metadata.viewing_direction || V3::DEFAULT_VIEWING_DIRECTION,
            'metadata' => iiif_metadata
          }
          hash['thumbnail'] = [thumbnail] if thumbnail.present?
          hash
        end

        # Required statement for attribution
        #
        # @return [Hash] attribution statement structure
        def required_statement
          {
            'label' => { 'none' => ['Attribution'] },
            'value' => { 'none' => ['Provided by the University of Pennsylvania Libraries.'] }
          }
        end

        # Generate manifest-level thumbnail
        #
        # @return [Hash] IIIF item thumbnail structure
        # @return [Hash] empty hash if no thumbnail available
        def thumbnail
          return {} unless item.thumbnail&.pyramidal_tiff

          ThumbnailBuilder.new(item.thumbnail).build
        end

        # Metadata to display in image viewer
        #
        # @return [Array<Hash>] array of metadata field structures
        def iiif_metadata
          metadata = [availability_metadata]
          metadata.concat(descriptive_metadata)
          metadata
        end

        # Availability metadata showing the public URL
        #
        # @return [Hash] availability metadata structure
        def availability_metadata
          {
            'label' => { 'none' => ['Available Online'] },
            'value' => { 'none' => [colenda.public_item_url(item.unique_identifier)] }
          }
        end

        # Build descriptive metadata from item fields
        #
        # @return [Array<Hash>] array of descriptive metadata structures
        def descriptive_metadata
          ItemResource::DescriptiveMetadata::Fields.all.filter_map do |field|
            values = item.descriptive_metadata.send(field)
            next if values.blank?

            {
              'label' => { 'none' => [field.to_s.titleize] },
              'value' => { 'none' => normalized_field_values(field, values) }
            }
          end
        end

        # Normalize field values based on field type
        #
        # @param field [Symbol] the metadata field name
        # @param values [Array] the field values
        # @return [Array<String>] normalized values
        def normalized_field_values(field, values)
          case field
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
        end

        # Check if PDF download should be available
        #
        # @return [Boolean] whether PDF can be generated
        def pdf_available?
          DerivativeService::Item::PDFGenerator.new(item.object).pdfable?
        end

        # Add PDF download to manifest rendering
        #
        # @param manifest [IIIF::V3::Presentation::Manifest] manifest to modify
        # @return [void]
        def add_pdf_download(manifest)
          manifest.rendering << {
            'id' => pdf_url,
            'label' => { 'en' => ['Download PDF'] },
            'type' => 'Text',
            'format' => 'application/pdf'
          }
        end

        # Get the pdf URL for this item
        #
        # @return [String] pdf url for download
        def pdf_url
          @pdf_url ||= "#{item_url}/pdf"
        end

        # Get the base URL for this item
        #
        # @return [String] item URL used as base for canvas and range IDs
        def item_url
          @item_url ||= "https://#{Settings.app_url}/#{V3::API_VERSION}/items/#{item.id}"
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
end
