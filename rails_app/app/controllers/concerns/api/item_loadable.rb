# frozen_string_literal: true

module API
  # Generalized logic for loading and authorizing items for ItemResource level API requests
  module ItemLoadable
    extend ActiveSupport::Concern

    included do
      before_action :load_item
      before_action :authorize_item
    end

    private

    # @raise [APIController::MissingIdentifierError]
    # @return [ItemResource]
    def load_item
      @item = if params[:uuid]
                find identifier: params[:uuid].to_s
              elsif params[:ark]
                find_by_ark ark: params[:ark].to_s
              else
                raise APIController::MissingIdentifierError, I18n.t('api.exceptions.missing_identifier')
              end
    end

    # @raise [APIController::ResourceMismatchError, APIController::NotPublishedError]
    # @return [Nil]
    def authorize_item
      unless @item.is_a? ItemResource
        raise APIController::ResourceMismatchError,
              I18n.t('api.exceptions.resource_mismatch', resource: ItemResource.to_s)
      end
      raise APIController::NotPublishedError, I18n.t('api.exceptions.not_published') unless @item.published
    end

    # @param ark [String] ark id
    # @raise [APIController::ResourceNotFound]
    # @return [ItemResource]
    def find_by_ark(ark:)
      item  = query_service.custom_queries.find_by_unique_identifier(unique_identifier: ark.to_s)
      raise APIController::ResourceNotFound, I18n.t('api.exceptions.not_found') unless item

      item
    end
  end
end
