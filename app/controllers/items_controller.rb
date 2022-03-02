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

  private

  def load_query_service
    @query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  def load_assets
    # @assets = @query_service.find_members resource: @item, model: AssetResource # TODO: doesn't work
    @assets = @query_service.find_many_by_ids ids: @item.asset_ids
  end
end
