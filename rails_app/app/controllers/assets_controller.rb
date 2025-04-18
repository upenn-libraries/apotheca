# frozen_string_literal: true

# actions for Assets
class AssetsController < ResourcesController
  class FileNotFound < StandardError; end
  class ItemNotFound < StandardError; end
  class UnsupportedFileType < StandardError; end
  class UnsupportedFileSize < StandardError; end

  before_action :set_asset, only: %i[show file edit update regenerate_derivatives destroy]
  before_action :set_item, only: %i[show new create edit update destroy]
  before_action :validate_file_size, only: %i[create update]

  # respond with a 404 for missing asset files or missing Item (when required)
  rescue_from 'AssetsController::FileNotFound', 'AssetsController::ItemNotFound' do |_e|
    head :not_found
  end

  # respond with a 500 for unsupported type requests
  rescue_from 'AssetsController::UnsupportedFileType' do |_e|
    head :bad_request
  end

  rescue_from 'AssetsController::UnsupportedFileSize' do |_e|
    redirect_back_or_to item_path(@item), alert: I18n.t('assets.file.size')
  end

  def show
    authorize! :show, @asset
  end

  def new
    authorize! :new, AssetResource
    @change_set = AssetChangeSet.new(AssetResource.new)
  end

  def edit
    authorize! :new, @asset
    @change_set = AssetChangeSet.new(@asset)
  end

  def create
    authorize! :create, AssetResource
    result = build_and_attach_asset
    if result.success?
      flash.notice = I18n.t('actions.asset.create.success')
      redirect_to asset_path(result.value!.id)
    else
      render_failure(result.failure, :new)
    end
  end

  def update
    authorize! :update, @asset

    UpdateAsset.new.call(id: @asset.id, updated_by: current_user.email, **asset_params, **file_params) do |result|
      result.success do |resource|
        flash.notice = I18n.t('actions.asset.update.success')
        redirect_to asset_path(resource)
      end

      result.failure do |failure|
        render_failure(failure, :edit)
      end
    end
  end

  def destroy
    authorize! :delete, @asset

    DeleteAsset.new.call(id: @asset.id, deleted_by: current_user.email) do |result|
      result.success do
        flash.notice = I18n.t('actions.asset.delete.success')
        redirect_to item_path @item, anchor: 'assets'
      end
      result.failure do |failure|
        render_failure(failure, :show)
      end
    end
  end

  def file
    case params[:type]
    when *AssetChangeSet::DERIVATIVE_TYPES
      serve_derivative_file resource: @asset, type: params[:type].to_sym
    when 'preservation'
      serve_preservation_file
    else
      raise UnsupportedFileType, 'Type is not supported'
    end
  end

  def regenerate_derivatives
    authorize! :update, @asset

    if GenerateDerivativesJob.perform_async(@asset.id.to_s, current_user.email)
      redirect_to asset_path(@asset), notice: I18n.t('actions.asset.regenerate_derivatives.success')
    else
      redirect_to asset_path(@asset), alert: I18n.t('actions.asset.regenerate_derivatives.failure')
    end
  end

  private

  # Creates asset, adds file to asset (if one is present), then attaches asset to item.
  # Note: This method does not require a file, therefore assets can be created without
  # an associated preservation file.
  def build_and_attach_asset
    # Create base asset.
    result = CreateAsset.new.call(**asset_params, created_by: current_user.email)
    return result if result.failure?

    # Add file to asset.
    update_result = UpdateAsset.new.call(id: result.value!.id, updated_by: current_user.email, **file_params)
    if update_result.failure?
      PurgeAsset.new.call(id: result.value!.id)
      return update_result
    end

    # Add Asset to Item.
    add_asset_result = AttachAsset.new.call(id: @item.id, asset_id: update_result.value!.id,
                                            updated_by: current_user.email)
    if add_asset_result.failure?
      PurgeAsset.new.call(id: result.value!.id)
      return add_asset_result
    end

    update_result
  end

  def render_failure(failure, template)
    if failure.key?(:change_set)
      @change_set = failure[:change_set]
      @asset = @change_set.resource
    end

    @error = failure
    @errors_for = params[:form]

    load_resources

    render template
  end

  def load_resources
    if @asset
      @change_set = AssetChangeSet.new(@asset)
    elsif params[:id]
      set_asset
      @change_set = AssetChangeSet.new(@asset)
    else
      @change_set = AssetChangeSet.new(AssetResource.new)
    end
  end

  def asset_params
    params.require(:asset).permit(:label, annotations: [:text], transcriptions: %i[contents mime_type])
  end

  def file_params
    params.require(:asset).permit(:file).tap do |p|
      p[:original_filename] = p[:file].original_filename if p[:file].is_a? ActionDispatch::Http::UploadedFile
    end
  end

  def serve_preservation_file
    raise FileNotFound, "No preservation file exists for asset #{@asset.id}" unless @asset.preservation_file_id

    file = Valkyrie::StorageAdapter.find_by id: @asset.preservation_file_id
    send_data file.read,
              type: @asset.technical_metadata.mime_type,
              disposition: file_disposition,
              filename: @asset.original_filename
  end

  def set_asset
    @asset = pg_query_service.find_by id: params[:id]
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    raise FileNotFound, e
  end

  def set_item
    @item = if params[:item_id]
              pg_query_service.find_by(id: params[:item_id])
            else
              pg_query_service.find_inverse_references_by(resource: @asset, property: :asset_ids).first
            end
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    raise ItemNotFound, e
  end

  # @return [nil]
  def validate_file_size
    return if file_params.blank?

    raise UnsupportedFileSize if file_params[:file].size >= Settings.virus_check.size_threshold
  end

  # Custom derivative filename.
  #
  # @param [DerivativeResource] derivative
  # @return [String]
  def derivative_filename(derivative)
    "#{File.basename(@asset.original_filename, '.*')}-#{derivative.type}.#{derivative.extension}"
  end
end
