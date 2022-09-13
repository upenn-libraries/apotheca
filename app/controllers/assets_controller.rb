# frozen_string_literal: true

# actions for Assets
class AssetsController < ApplicationController
  class FileNotFound < StandardError; end
  class UnsupportedFileType < StandardError; end

  before_action :set_asset, only: [:file]

  def file
    case params[:type].to_sym
    when :thumbnail
      serve_thumbnail_file
    when :access
      serve_access_file
    when :preservation
      serve_preservation_file
    else
      raise UnsupportedFileType, 'Type is not supported'
    end
  end

  private

  def serve_thumbnail_file
    thumbnail_resource = @asset.thumbnail
    raise FileNotFound, "No thumbnail exists for asset #{@asset.id}" unless thumbnail_resource

    file = derivatives_storage_adapter.find_by id: thumbnail_resource.file_id
    send_data file.read,
              type: thumbnail_resource.mime_type,
              disposition: file_disposition,
              filename: 'thumbnail'
  end

  def serve_access_file
    access_resource = @asset.access
    raise FileNotFound, "No access copy exists for asset #{@asset.id}" unless access_resource

    file = derivatives_storage_adapter.find_by id: access_resource.file_id
    send_data file.read,
              type: access_resource.mime_type,
              disposition: file_disposition,
              filename: 'access'
  end

  def serve_preservation_file
    raise FileNotFound, "No preservation file exists for asset #{@asset.id}" unless @asset.preservation_file_id

    file = preservation_storage_adapter.find_by id: @asset.preservation_file_id
    send_data file.read,
              type: @asset.technical_metadata.mime_type,
              disposition: file_disposition,
              filename: @asset.original_filename || @asset.id
  end

  # @return [String]
  def file_disposition
    return 'inline' if params[:disposition] == 'inline'

    'attachment'
  end

  def set_asset
    @asset = metadata_adapter.query_service.find_by id: params[:id]
  end

  def metadata_adapter
    @metadata_adapter ||= Valkyrie::MetadataAdapter.find(:postgres)
  end

  def derivatives_storage_adapter
    @derivatives_storage_adapter ||= Valkyrie::StorageAdapter.find :derivatives
  end

  # TODO: use preservation_copy?
  def preservation_storage_adapter
    @preservation_storage_adapter ||= Valkyrie::StorageAdapter.find :preservation
  end
end
