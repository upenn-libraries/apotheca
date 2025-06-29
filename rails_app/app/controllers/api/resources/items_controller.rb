# frozen_string_literal: true

module API
  module Resources
    # API actions for ItemResources
    class ItemsController < APIController
      before_action :load_item, except: :lookup
      before_action :authorize_item

      def show; end

      def lookup; end

      def preview; end

      def pdf
        pdf_derivative = @item.pdf

        raise FileNotFound, I18n.t('api.exceptions.file_not_found') unless pdf_derivative

        filename = "#{@item.presenter.descriptive_metadata.title.first[:value].parameterize}.pdf"

        redirect_to_presigned_url pdf_derivative.file_id, filename
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
