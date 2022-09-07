# frozen_string_literal: true

# controller actions for Item stuff
class ItemsController < ApplicationController
  before_action :load_and_authorize_resources, only: [:show, :edit]

  rescue_from 'Valkyrie::Persistence::ObjectNotFoundError', with: :error_redirect

  def index
    authorize! :read, ItemResource
    items_container = solr_query_service.custom_queries.item_index parameters: search_params
    @items = items_container.items
    @facets = items_container.facets
  end

  def show
    authorize! :read, @item
  end

  def edit
    authorize! :edit, @item
  end

  def update
    authorize! :edit, ItemResource
    @item = pg_query_service.find_by id: params[:id]
    Item.new(@item).update(update_params[:item])
    redirect_to edit_item_path(@item)
  end

  private

  def update_params
    metadata_fields = ItemResource::DescriptiveMetadata::FIELDS.map { |f| [f, []] }.to_h
    params.permit(item: {
      descriptive_metadata: metadata_fields,
      structural_metadata: [:viewing_direction, :viewing_hint]
    })
  end

  # @return [Valkyrie::MetadataAdapter]
  def pg_query_service
    @pg_query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  # @return [Valkyrie::MetadataAdapter]
  def solr_query_service
    @solr_query_service ||= Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  def load_and_authorize_resources
    @item = pg_query_service.find_by id: params[:id]
    @assets = pg_query_service.find_references_by resource: @item, property: :asset_ids, model: AssetResource
  end

  # @param [StandardError] exception
  def error_redirect(exception)
    redirect_to items_path, notice: "Problem loading page: #{exception.message}"
  end

  def search_params
    params.permit(:keyword, :sort_field, :sort_direction, :rows, filters: {})
  end
end
