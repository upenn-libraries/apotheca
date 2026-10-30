# frozen_string_literal: true

# Helpers for loading ItemResource.
module ItemLoadable
  extend ActiveSupport::Concern

  # Load Item
  def load_item
    resource = Query.postgres.find_by(id: params[:id])

    @item = resource.presenter
  rescue Valkyrie::Persistence::ObjectNotFoundError
    head :not_found
  end
end
