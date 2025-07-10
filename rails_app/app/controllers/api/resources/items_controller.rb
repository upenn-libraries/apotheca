# frozen_string_literal: true

module API
  module Resources
    # API actions for ItemResources
    class ItemsController < APIController
      class InvalidSize < InvalidParameterError; end

      before_action :load_item
      before_action :authorize_item
      before_action :parse_size!, only: :preview

      DEFAULT_SIZE = 200
      MAX_SIZE = 600

      def show; end

      def lookup
        render :show
      end

      # Returns preview image for Item. If requested image size is 200,200 or nil redirects to
      # thumbnail, otherwise redirects to IIIF image service.
      def preview
        if @width == DEFAULT_SIZE && @height == DEFAULT_SIZE && @item.thumbnail_image?
          filename = "#{@item.presenter.parameterize}-thumbnail.jpeg"
          redirect_to_presigned_url @item.thumbnail.thumbnail.file_id, filename
        elsif @item.thumbnail&.iiif_image&.mime_type == 'image/tiff'
          redirect_to_iiif_image_server @item.thumbnail, "!#{@width},#{@height}"
        else
          raise FileNotFound, I18n.t('api.exceptions.file_not_found')
        end
      end

      def pdf
        pdf_derivative = @item.pdf

        raise FileNotFound, I18n.t('api.exceptions.file_not_found') unless pdf_derivative

        filename = "#{@item.presenter.parameterize}.pdf"

        redirect_to_presigned_url pdf_derivative.file_id, filename
      end

      private

      def load_item
        @item = if params[:uuid]
                  find identifier: params[:uuid].to_s
                elsif params[:ark]
                  find_by_ark ark: params[:ark].to_s
                else
                  raise MissingIdentifierError, I18n.t('api.exceptions.missing_identifier')
                end
      end

      def authorize_item
        unless @item.is_a? ItemResource
          raise ResourceMismatchError, I18n.t('api.exceptions.resource_mismatch', resource: ItemResource.to_s)
        end
        raise NotPublishedError, I18n.t('api.exceptions.not_published') unless @item.published
      end

      # @param ark [String] id
      # @return [ItemResource]
      def find_by_ark(ark:)
        query_service.custom_queries.find_by_unique_identifier(unique_identifier: ark.to_s)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        raise ResourceNotFound, I18n.t('api.exceptions.not_found')
      end

      def parse_size!
        size = /^(\d{1,3}),(\d{1,3})$/.match(params.fetch(:size, "#{DEFAULT_SIZE},#{DEFAULT_SIZE}"))

        raise InvalidSize, I18n.t('api.exceptions.invalid_param.size') unless size

        @width = size[1].to_i
        @height = size[2].to_i

        raise InvalidSize, I18n.t('api.exceptions.invalid_param.size') if @width > MAX_SIZE || @height > MAX_SIZE
      end
    end
  end
end
