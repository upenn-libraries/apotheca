# frozen_string_literal: true

module API
  module IIIF
    # API actions for Item-level IIIF-compliant responses
    class ItemsController < APIController
      before_action :load_item
      before_action :authorize_item

      # /iiif/items/:uuid/manifest
      def manifest
        manifest = @item.iiif_v3_manifest

        raise FileNotFound, I18n.t('api.exceptions.file_not_found') unless manifest

        response.headers['Access-Control-Allow-Origin'] = '*'
        manifest_file_id = @item.iiif_v3_manifest.file_id

        redirect_to_json(manifest_file_id)
      end

      private

      def load_item
        @item = find identifier: params[:uuid].to_s
      end

      def authorize_item
        raise ResourceMismatchError, I18n.t('api.exceptions.resource_mismatch') unless @item.is_a? ItemResource
        raise NotPublishedError, I18n.t('api.exceptions.not_published') unless @item.published
      end
    end
  end
end
