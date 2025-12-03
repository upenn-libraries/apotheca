# frozen_string_literal: true

# Helpers for loading ItemResource.
module ItemLoadable
  extend ActiveSupport::Concern

  # Load Item
  def load_item
    @item = pg_query_service.find_by(id: params[:id])
  rescue Valkyrie::Persistence::ObjectNotFoundError
    head :not_found
  end

  # Postgres query service.
  #
  # @return [Valkyrie::MetadataAdapter]
  def pg_query_service
    @pg_query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
