# frozen_string_literal: true

module Items
  # Actions to bulk download files from all of an Item's child Assets.
  class BulkDownloadController < UIController
    include ItemLoadable

    before_action :load_item, :authorize_bulk_download

    # Download the preservation file of each related asset.
    def preservation
      zip_kit_stream(filename: "#{@item.human_readable_name.parameterize}.zip") do |zip|
        @item.assets.each do |asset|
          next if asset.preservation_file_id.blank?

          file = Valkyrie::StorageAdapter.find_by id: asset.preservation_file_id
          zip.write_file(asset.original_filename) do |sink|
            IO.copy_stream(file.io, sink)
          end
        end
      rescue StandardError => e
        raise 'Error downloading preservation files', cause: e
      end
    end

    # Download the access file of each related asset. In the case of images, a JPEG
    # is fetched from the IIIF serverless service.
    def access
      zip_kit_stream(filename: "#{@item.human_readable_name.parameterize}-access.zip") do |zip|
        @item.assets.each do |asset|
          add_access_file(zip, asset)
        end
      rescue StandardError => e
        raise 'Error downloading access files', cause: e
      end
    end

    private

    # Adding access file to zip.
    # In cases where there is no access or iiif_image derivative, no access copy is added.
    def add_access_file(zip, asset)
      if asset.access
        add_access_derivative(zip, asset)
      elsif asset.iiif_image
        add_iiif_image(zip, asset)
      end
    end

    # Adding access derivative to zip.
    def add_access_derivative(zip, asset)
      file = Valkyrie::StorageAdapter.find_by id: asset.access.file_id
      filename = "#{File.basename(asset.original_filename, '.*')}.#{asset.access.extension}"

      zip.write_file(filename) do |sink|
        IO.copy_stream(file.io, sink)
      end
    end

    # Adding JPEG from IIIF Image Service to zip.
    def add_iiif_image(zip, asset)
      uri = URI(asset.iiif_image_url)
      filename = "#{File.basename(asset.original_filename, '.*')}.jpg"

      zip.write_file(filename) do |sink|
        Net::HTTP.get_response(uri) do |response|
          response.read_body(sink)
        end
      end
    end

    def authorize_bulk_download
      authorize! :read, @item
    end
  end
end
