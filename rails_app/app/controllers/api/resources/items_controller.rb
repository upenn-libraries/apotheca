# frozen_string_literal: true

module API
  module Resources
    # API actions for ItemResources
    class ItemsController < APIController
      before_action :load_item
      before_action :authorize_item

      def show; end

      def lookup
        render :show
      end

      def preview; end

      def pdf
        pdf_derivative = @item.pdf

        raise FileNotFound, I18n.t('api.exceptions.file_not_found') unless pdf_derivative

        filename = "#{@item.presenter.descriptive_metadata.title.first[:value].parameterize}.pdf"

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
    end
  end
end
