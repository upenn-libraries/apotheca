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

    result = UpdateItem.new.call(id: params[:id], updated_by: current_user.email, **update_params[:item])
    if result.success?
      # flash.notice = 'Successfully updated item.'
      redirect_to edit_item_path(result.value!), notice: 'Successfully updated item.'
    else
      # For right now, we need to have access to the items and assets if we are rendering the edit page. In future,
      # we will submit the form via ajax and return just the errors if there is a failure.
      load_and_authorize_resources
      flash.alert = result.failure
      render :edit
    end
  end

  private

  def update_params
    metadata_fields = ItemResource::DescriptiveMetadata::FIELDS.map { |f| [f, []] }.to_h
    params.permit(item: [
                    :thumbnail_asset_id,
                    { internal_notes: [],
                      descriptive_metadata: metadata_fields,
                      structural_metadata: [:viewing_direction, :viewing_hint] }
                  ])
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
    @arranged_assets = pg_query_service.find_many_by_ids ids: @item.structural_metadata.arranged_asset_ids
    @unarranged_assets = pg_query_service.find_many_by_ids ids: @item.unarranged_asset_ids
  end

  # @param [StandardError] exception
  def error_redirect(exception)
    redirect_to items_path, notice: "Problem loading page: #{exception.message}"
  end

  def search_params
    params.permit(:keyword, :sort_field, :sort_direction, :rows, filters: {})
  end
end
