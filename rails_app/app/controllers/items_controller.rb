# frozen_string_literal: true

# controller actions for Item stuff
class ItemsController < ResourcesController
  before_action :load_item_and_change_set, except: :index
  before_action :load_assets, only: %i[show edit reorder_assets]
  before_action :configure_pagination, only: :index
  before_action :store_rows, only: :index

  authorize_resource :item_resource, parent: false

  rescue_from 'Valkyrie::Persistence::ObjectNotFoundError', with: :error_redirect

  def index
    @container = solr_query_service.custom_queries.item_index parameters: search_params
  end

  def show; end

  def new; end

  def edit; end

  def create
    CreateItem.new.call(created_by: current_user.email, **item_params) do |result|
      result.success do |resource|
        flash.notice = I18n.t('actions.item.create.success')
        redirect_to item_path(resource)
      end

      result.failure do |failure|
        render_failure(failure, :new)
      end
    end
  end

  def update
    UpdateItem.new.call(id: params[:id], updated_by: current_user.email, **item_params) do |result|
      result.success do |resource|
        flash.notice = I18n.t('actions.item.update.success')
        redirect_to item_path(resource, anchor: params[:form])
      end

      result.failure do |failure|
        render_failure(failure, :edit)
      end
    end
  end

  def destroy
    DeleteItem.new.call(id: params[:id], deleted_by: current_user.email) do |result|
      result.success do
        flash.notice = I18n.t('actions.item.delete.success')
        redirect_to items_path
      end
      result.failure do |failure|
        render_failure(failure, :show)
      end
    end
  end

  def reorder_assets; end

  def file
    case params[:type]
    when *ItemChangeSet::DERIVATIVE_TYPES
      serve_derivative_file resource: @item, type: params[:type].to_sym
    else
      raise UnsupportedFileType, 'Type is not supported'
    end
  end

  def refresh_ils_metadata
    if RefreshIlsMetadataJob.perform_async(@item.id.to_s, current_user.email)
      redirect_to item_path(@item), notice: I18n.t('actions.item.refresh_ILS.success')
    else
      redirect_to items_path(@item), alert: I18n.t('actions.item.refresh_ILS.failure')
    end
  end

  def publish
    if PublishItemJob.perform_async(@item.id.to_s, current_user.email)
      redirect_to item_path(@item), notice: I18n.t('actions.item.publish.success')
    else
      redirect_to items_path(@item), alert: I18n.t('actions.item.publish.failure')
    end
  end

  def unpublish
    UnpublishItem.new.call(id: params[:id], updated_by: current_user.email) do |result|
      result.success do |resource|
        flash.notice = I18n.t('actions.item.unpublish.success')
        redirect_to item_path(resource)
      end
      result.failure do |failure|
        render_failure(failure, :show)
      end
    end
  end

  def refresh_all_ils_metadata
    if EnqueueBulkRefreshIlsMetadataJob.perform_async(current_user.email)
      redirect_to system_actions_path, notice: I18n.t('actions.item.refresh_all_ILS.success')
    else
      redirect_to system_actions_path, notice: I18n.t('actions.item.refresh_all_ILS.failure')
    end
  end

  private

  # Explicitly set the default per page for initial page load (when there are no params) only for the ItemResource
  # case. With AR models, this config can be specified in the model. I do this here to avoid setting a default app-wide
  # config that might later be altered and break proper page counts when rendering the paginator in the item index.
  def configure_pagination
    Kaminari.configure do |config|
      config.default_per_page = Solr::QueryMaps::Item::ROWS_OPTIONS.min
    end
  end

  def store_rows
    if params[:rows].present?
      session[:item_rows] = params[:rows]
    else
      params[:rows] = session[:item_rows]
    end
  end

  # Handle Failure response from transaction. Set appropriate ivars based on Failure contents and template to render.
  def render_failure(failure, template)
    load_item_and_change_set failure[:change_set]
    load_assets if [:edit, :show].include?(template)

    @error = failure
    @errors_for = params[:form]

    render template
  end

  # Load item and change_set ivars for views. Use ItemPresenter for all views, load ILS metadata only as needed.
  # @param [ItemChangeSet] change_set, optional
  def load_item_and_change_set(change_set = nil)
    resource = if change_set
                 change_set.resource
               elsif params[:id]
                 pg_query_service.find_by(id: params[:id])
               else
                 ItemResource.new
               end
    @item = resource.presenter
    @change_set = change_set || ItemChangeSet.new(resource)
  end

  def load_assets
    @arranged_assets = @item.arranged_assets
    @unarranged_assets = pg_query_service.find_many_by_ids ids: @item.unarranged_asset_ids.deep_dup
  end

  # @param [StandardError] exception
  def error_redirect(exception)
    redirect_to items_path, notice: "Problem loading page: #{exception.message}"
  end

  def item_params
    metadata_fields = ItemResource::DescriptiveMetadata::Fields::CONFIG.transform_values do |type|
      case type
      when :text
        [:value]
      when :term
        [:value, :uri]
      when :name
        [:value, :uri, { role: [:value, :uri] }]
      end
    end

    params.require(:item).permit(
      :human_readable_name, :thumbnail_asset_id, :ocr_type,
      internal_notes: [],
      descriptive_metadata: metadata_fields,
      structural_metadata: [
        :viewing_direction, :viewing_hint,
        { arranged_asset_ids: [] }
      ]
    )
  end

  def search_params
    params.permit(:keyword, :rows, :page, filter: {}, sort: {}, search: {})
  end

  # Custom derivative filename.
  #
  # @param [DerivativeResource] derivative
  # @return [String]
  def derivative_filename(derivative)
    "#{@item.human_readable_name.parameterize}.#{derivative.extension}"
  end

  # @return [Valkyrie::MetadataAdapter]
  def solr_query_service
    @solr_query_service ||= Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end
end
