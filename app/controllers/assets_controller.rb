# frozen_string_literal: true

# actions for Assets
class AssetsController < ApplicationController
  class FileNotFound < StandardError; end
  class UnsupportedFileType < StandardError; end

  before_action :set_asset, only: [:file]

  def file
    case params[:type].to_sym
    when :thumbnail, :access
      serve_derivative_file type: params[:type].to_sym
    when :preservation
      serve_preservation_file
    else
      raise UnsupportedFileType, 'Type is not supported'
    end
  end

  private

  def serve_derivative_file(type:)
    resource = @asset.send(type)
    raise FileNotFound, "No #{type} derivative exists for asset #{@asset.id}" unless resource

    file = Valkyrie::StorageAdapter.find_by id: resource.file_id
    send_data file.read,
              type: resource.mime_type,
              disposition: file_disposition,
              filename: type.to_s
  end

  def serve_preservation_file
    raise FileNotFound, "No preservation file exists for asset #{@asset.id}" unless @asset.preservation_file_id

    file = preservation_storage_adapter.find_by id: @asset.preservation_file_id
    send_data file.read,
              type: @asset.technical_metadata.mime_type,
              disposition: file_disposition,
              filename: @asset.original_filename
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
end
