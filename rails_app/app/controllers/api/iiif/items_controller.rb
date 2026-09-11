# frozen_string_literal: true

module API
  module IIIF
    # API actions for Item-level IIIF-compliant responses
    class ItemsController < APIController
      include ItemLoadable

      before_action :load_manifest, only: :manifest

      # Return IIIF manifest. Support returning v2 and v3 manifests. Defaults to returning v3 manifests.
      # /iiif(/:version)/items/:uuid/manifest
      def manifest
        response.headers['Access-Control-Allow-Origin'] = '*'

        if @manifest
          serve_json(@manifest.file_id)
        else
          raise FileNotFound, I18n.t('api.exceptions.file_not_found')
        end
      end

      private

      def load_manifest
        @manifest = case params[:version]
                    when '2'
                      @item.iiif_manifest
                    when '3'
                      @item.iiif_v3_manifest
                    else
                      raise 'IIIF version number not supported'
                    end
      end
    end
  end
end
