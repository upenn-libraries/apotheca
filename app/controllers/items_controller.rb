# frozen_string_literal: true

# controller actions for Item stuff
class ItemsController < ApplicationController
  before_action :load_query_service

  def index
    @items = @query_service.find_all_of_model model: ItemResource
  end

  def show
    @item = @query_service.find_by id: params[:id]
    load_assets
  end

  def edit
    @item = @query_service.find_by id: params[:id]
  end

  def update
    @item = @query_service.find_by id: params[:id]
    Item.new(@item).update(update_params[:item])
    redirect_to item_path(@item)
  end

  private

  def update_params
    metadata_fields = ItemResource::DescriptiveMetadata::FIELDS.map { |f| [f, []] }.to_h
    params.permit(item: { descriptive_metadata: metadata_fields })
  end

  def load_query_service
    @query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  def load_assets
    @assets = @query_service.find_references_by resource: @item, property: :asset_ids, model: AssetResource
  end
end
