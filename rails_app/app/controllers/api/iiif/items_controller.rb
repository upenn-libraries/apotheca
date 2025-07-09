# frozen_string_literal: true

module API
  module IIIF
    # API actions for Item-level IIIF-compliant responses
    class ItemsController < APIController
      include ItemLoadable

      # /iiif/items/:uuid/manifest
      def manifest
        manifest = @item.iiif_v3_manifest

        raise FileNotFound, I18n.t('api.exceptions.file_not_found') unless manifest

        response.headers['Access-Control-Allow-Origin'] = '*'
        manifest_file_id = @item.iiif_v3_manifest.file_id

        redirect_to_json(manifest_file_id)
      end
    end
  end
end
