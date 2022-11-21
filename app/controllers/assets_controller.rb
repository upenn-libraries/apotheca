# frozen_string_literal: true

# actions for Assets
class AssetsController < ApplicationController
  class FileNotFound < StandardError; end
  class ItemNotFound < StandardError; end
  class UnsupportedFileType < StandardError; end

  before_action :set_asset, only: [:show, :file]
  before_action :set_item, only: [:show, :new, :create]

  # respond with a 404 for missing asset files or missing Item (when required)
  rescue_from 'AssetsController::FileNotFound', 'AssetsController::ItemNotFound' do |_e|
    head :not_found
  end

  # respond with a 500 for unsupported type requests
  rescue_from 'AssetsController::UnsupportedFileType' do |_e|
    head :bad_request
  end

  def show
    authorize! :show, @asset
  end

  def new
    authorize! :new, AssetResource
    @change_set = AssetChangeSet.new(AssetResource.new)
  end

  def create
    authorize! :create, AssetResource

    CreateAsset.new.call(**asset_params, created_by: current_user.email) do |result|
      result.success do |resource|
        AddAsset.new.call(id: @item.id, asset_id: resource.id, updated_by: current_user.email) do |add_asset_result|
          add_asset_result.success do
            flash.notice = 'Successfully created asset.'
            redirect_to asset_path(resource) # TODO: This should redirect to the edit page.
          end

          add_asset_result.failure do |failure|
            DeleteAsset.new.call(id: resource.id) # Delete Asset because it was not properly attached to Item
            render_failure(failure, :new)
          end
        end
      end

      result.failure do |failure|
        render_failure(failure, :new)
      end
    end
  end

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

  def render_failure(failure, template)
    @change_set = failure[:change_set]
    @error = failure

    render :new
  end

  def asset_params
    params.require(:asset).permit(:label, annotations: [:text], transcriptions: [:contents, :mime_type])
  end

  # @param [Symbol] type
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

    file = Valkyrie::StorageAdapter.find_by id: @asset.preservation_file_id
    send_data file.read,
              type: @asset.technical_metadata.mime_type,
              disposition: file_disposition,
              filename: @asset.original_filename
  end

  # @return [Symbol]
  def file_disposition
    return :inline if params[:disposition] == 'inline'

    :attachment
  end

  def set_asset
    @asset = metadata_adapter.query_service.find_by id: params[:id]
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    raise FileNotFound, e
  end

  def set_item
    @item = if params[:item_id]
              metadata_adapter.query_service.find_by(id: params[:item_id])
            else
              metadata_adapter.query_service.find_inverse_references_by(resource: @asset, property: :asset_ids).first
            end

  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    raise ItemNotFound, e
  end

  # @return [Valkyrie::MetadataAdapter]
  def metadata_adapter
    @metadata_adapter ||= Valkyrie::MetadataAdapter.find(:postgres)
  end
end
