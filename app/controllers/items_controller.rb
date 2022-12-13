# frozen_string_literal: true

# controller actions for Item stuff
class ItemsController < ApplicationController
  before_action :configure_pagination, only: :index
  before_action :load_resources, only: [:show, :edit]

  rescue_from 'Valkyrie::Persistence::ObjectNotFoundError', with: :error_redirect

  def index
    authorize! :read, ItemResource
    @container = solr_query_service.custom_queries.item_index parameters: search_params
  end

  def show
    authorize! :read, @item
  end

  def new
    authorize! :new, ItemResource
    @item = ItemResource.new
    @change_set = ItemChangeSet.new(@item)
  end

  def edit
    authorize! :edit, @item
  end

  def create
    authorize! :create, ItemResource

    CreateItem.new.call(created_by: current_user.email, **item_params) do |result|
      result.success do |resource|
        flash.notice = 'Successfully created item.'
        redirect_to edit_item_path(resource)
      end

      result.failure do |failure|
        render_failure(failure, :new)
      end
    end
  end

  def update
    authorize! :edit, ItemResource

    UpdateItem.new.call(id: params[:id], updated_by: current_user.email, **item_params) do |result|
      result.success do |resource|
        flash.notice = 'Successfully updated item.'
        redirect_to edit_item_path(resource, anchor: params[:form])
      end

      result.failure do |failure|
        render_failure(failure, :edit)
      end
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

  def render_failure(failure, template)
    if failure.key?(:change_set)
      @change_set = failure[:change_set]
      @item = @change_set.resource
    end

    @error = failure
    @errors_for = params[:form]

    load_resources

    render template
  end

  def item_params
    metadata_fields = ItemResource::DescriptiveMetadata::FIELDS.map { |f| [f, []] }.to_h
    params.require(:item).permit(
      :human_readable_name, :thumbnail_asset_id,
      internal_notes: [],
      descriptive_metadata: metadata_fields,
      structural_metadata: [:viewing_direction, :viewing_hint]
    )
  end

  # @return [Valkyrie::MetadataAdapter]
  def pg_query_service
    @pg_query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  # @return [Valkyrie::MetadataAdapter]
  def solr_query_service
    @solr_query_service ||= Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  def load_resources
    @item ||= pg_query_service.find_by id: params[:id]
    @change_set ||= ItemChangeSet.new(@item)
    @arranged_assets = pg_query_service.find_many_by_ids ids: @item.structural_metadata.arranged_asset_ids.deep_dup
    @unarranged_assets = pg_query_service.find_many_by_ids ids: @item.unarranged_asset_ids.deep_dup
  end

  # @param [StandardError] exception
  def error_redirect(exception)
    redirect_to items_path, notice: "Problem loading page: #{exception.message}"
  end

  def search_params
    params.permit(:keyword, :rows, :page, filter: {}, sort: {}, search: {})
  end
end
