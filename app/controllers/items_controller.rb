# frozen_string_literal: true

# controller actions for Item stuff
class ItemsController < ApplicationController
  before_action :load_resources, only: [:show, :edit]

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

    UpdateItem.new.call(id: params[:id], updated_by: current_user.email, **update_params[:item]) do |result|
      result.success do |resource|
        flash.notice = 'Successfully updated item.'
        redirect_to edit_item_path(resource, anchor: params[:form])
      end

      result.failure :validate do |failure|
        @change_set = failure[:change_set]
        @item = @change_set.resource

        render_failure(failure)
      end

      result.failure do |failure|
        render_failure(failure)
      end
    end
  end

  private

  def render_failure(failure)
    load_resources
    @error = failure
    @errors_for = params[:form]

    render :edit
  end

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

  def load_resources
    @item ||= pg_query_service.find_by id: params[:id]
    @change_set ||= ItemChangeSet.new(@item)
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
