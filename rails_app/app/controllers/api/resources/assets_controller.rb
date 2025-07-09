# frozen_string_literal: true

module API
  module Resources
    # API actions for AssetResources
    class AssetsController < APIController
      class FileTypeError < InvalidParameterError; end

      FILES = %w[thumbnail access preservation].freeze
      IIIF_IMAGE_SIZE = 'max'

      before_action :load_asset
      before_action :load_item
      def show; end

      def file
        type = params[:file]

        raise FileTypeError, I18n.t('api.exceptions.invalid_param.file_type', type: type) unless type.in? FILES

        return redirect_to_derivative_file(type) if type.in? FILES - ['preservation']

        redirect_to_preservation_file
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

      # @param type [ActionController::Parameters]
      def redirect_to_derivative_file(type)
        derivative = @asset.send(type.to_sym)
        raise FileNotFound, I18n.t('api.exceptions.file_not_found') unless derivative

        filename = "#{File.basename(@asset.original_filename,
                                    File.extname(@asset.original_filename))}-#{type}.#{derivative.extension}"

        redirect_to_presigned_url(derivative.file_id, filename)
      end

      def redirect_to_preservation_file
        redirect_to_presigned_url(@asset.preservation_file_id, @asset.original_filename)
      end
    end
  end
end
