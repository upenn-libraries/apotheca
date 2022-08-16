# frozen_string_literal: true

# controller actions for Item stuff
class ItemsController < ApplicationController
  before_action :load_query_service

  def index
    authorize! :read, ItemResource
    @items = solr_query_service.custom_queries.item_index parameters: params
  end

  # def show
  #   authorize! :read, @item
  # end

  def edit
    authorize! :edit, ItemResource
    @item = @query_service.find_by id: params[:id]
    load_assets
  end

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

  def load_assets
    @assets = @query_service.find_references_by resource: @item, property: :asset_ids, model: AssetResource
  end
end
