# frozen_string_literal: true

module API
  module Resources
    # API actions for AssetResources
    class AssetsController < APIController
      before_action :load_asset
      before_action :load_item
      def show; end

      def file; end

      private

      def load_asset
        @asset = find identifier: params[:uuid].to_s
        return if @asset.is_a? AssetResource

        raise ResourceMismatchError, I18n.t('api.exceptions.resource_mismatch', resource: AssetResource.to_s)
      end

      def load_item
        @item = Valkyrie::MetadataAdapter.find(:postgres).query_service
                                         .find_inverse_references_by(resource: @asset, property: :asset_ids)
                                         .first
        raise ResourceNotFound, I18n.t('api.exceptions.not_found') if @item.nil?
        raise NotPublishedError, I18n.t('api.exceptions.not_published') unless @item.published
      end
    end
  end
end
