# frozen_string_literal: true

# controller actions for Item stuff
class ItemsController < ApplicationController
  before_action :load_query_service
  before_action :load_and_authorize_resources, only: [:show, :edit]

  def index
    authorize! :read, ItemResource
    items_container = solr_query_service.custom_queries.item_index parameters: search_params
    @items = items_container.items
    @facets = items_container.facets
  end

  def show; end

  def edit; end

  def update
    authorize! :edit, ItemResource
    @item = @query_service.find_by id: params[:id]
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

  def load_query_service
    @query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  def solr_query_service
    @solr_query_service = Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  def load_and_authorize_resources
    @item = @query_service.find_by id: params[:id]
    authorize! :read, @item
    @assets = @query_service.find_references_by resource: @item, property: :asset_ids, model: AssetResource
  end

  def search_params
    params.permit(:keyword, :sort_field, :sort_direction, :rows, filters: {})
  end
end
