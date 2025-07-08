# frozen_string_literal: true

module API
  module Resources
    # API actions for AssetResources
    class AssetsController < APIController
      class FileTypeError < InvalidParameterError; end

      FILES = %w[thumbnail iiif_image preservation].freeze
      IIIF_IMAGE_SIZE = 'max'

      before_action :load_asset
      before_action :load_item
      def show; end

      def file
        type = params[:file]

        raise FileTypeError, I18n.t('api.exceptions.invalid_param.file_type', type: type) unless type.in? FILES

        redirect_to_file(type)
      end

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

      def redirect_to_file(type)
        case type
        when 'thumbnail' then redirect_to_presigned_url(@asset.thumbnail.file_id, thumbnail_filename)
        when 'iiif_image' then redirect_to_iiif_image_server(@asset, IIIF_IMAGE_SIZE)
        when 'preservation' then redirect_to_presigned_url(@asset.preservation_file_id, @asset.original_filename)
        else
          raise FileTypeError, I18n.t('api.exceptions.invalid_param.file_type', type: type)
        end
      end

      # @return [String]
      def thumbnail_filename
        "#{File.basename(@asset.original_filename,
                         File.extname(@asset.original_filename))}-thumbnail.#{@asset.thumbnail.extension}"
      end
    end
  end
end
