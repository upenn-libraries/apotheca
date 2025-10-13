# frozen_string_literal: true

module API
  module Resources
    # API actions for AssetResources
    class AssetsController < APIController
      include AssetLoadable

      class FileTypeError < InvalidParameterError; end

      FILES = %w[thumbnail access preservation].freeze
      IIIF_IMAGE_SIZE = 'max'

      def show; end

      def file
        type = params[:file]

        raise FileTypeError, I18n.t('api.exceptions.invalid_param.file_type', type: type) unless type.in? FILES

        return redirect_to_derivative_file(type) if type.in? FILES - ['preservation']

        redirect_to_preservation_file
      end

      private

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
