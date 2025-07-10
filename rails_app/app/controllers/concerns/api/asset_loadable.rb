# frozen_string_literal: true

module API
  # Generalized logic for loading and authorizing assets for AssetResource level API requests
  module AssetLoadable
    extend ActiveSupport::Concern

    included do
      before_action :load_asset
      before_action :load_item
    end

    private

    def load_asset
      @asset = find identifier: params[:uuid].to_s
      return if @asset.is_a? AssetResource

      raise APIController::ResourceMismatchError,
            I18n.t('api.exceptions.resource_mismatch', resource: AssetResource.to_s)
    end

    def load_item
      @item = Valkyrie::MetadataAdapter.find(:postgres).query_service
                                       .find_inverse_references_by(resource: @asset, property: :asset_ids)
                                       .first
      raise APIController::ResourceNotFound, I18n.t('api.exceptions.not_found') if @item.nil?
      raise APIController::NotPublishedError, I18n.t('api.exceptions.not_published') unless @item.published
    end
  end
end
