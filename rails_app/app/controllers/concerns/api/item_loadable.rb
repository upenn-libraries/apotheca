# frozen_string_literal: true

module API
  # Generalized logic for loading and authorizing items for ItemResource level API requests
  module ItemLoadable
    extend ActiveSupport::Concern

    included do
      before_action :load_item
      before_action :authorize_item!
    end

    private

    # Load the resource from either +uuid+ or +ark+ param and validate that the returned resource is an ItemResource,
    # then set +@item+ to the ItemPresenter.
    # @raise [APIController::MissingIdentifierError]
    # @raise [APIController::ResourceMismatchError]
    # @return [ItemPresenter]
    def load_item
      resource = find_resource_from_params

      unless resource.is_a? ItemResource
        raise APIController::ResourceMismatchError,
              I18n.t('api.exceptions.resource_mismatch', resource: ItemResource.to_s)
      end

      @item = resource.presenter
    end

    # Lookup resource, raising error if no suitable identifier is present.
    # @raise [APIController::MissingIdentifierError]
    # @return [Valkyrie::Resource, nil]
    def find_resource_from_params
      return find(identifier: params[:uuid].to_s) if params[:uuid].present?
      return find_by_ark(ark: params[:ark].to_s) if params[:ark].present?

      raise APIController::MissingIdentifierError, I18n.t('api.exceptions.missing_identifier')
    end

    # @raise [APIController::NotPublishedError]
    # @return [nil]
    def authorize_item!
      raise APIController::NotPublishedError, I18n.t('api.exceptions.not_published') unless @item.published
    end

    # @raise [APIController::ResourceNotFound]
    # @param ark [String] ark id
    # @return [ItemResource]
    def find_by_ark(ark:)
      item  = query_service.custom_queries.find_by_unique_identifier(unique_identifier: ark.to_s)
      raise APIController::ResourceNotFound, I18n.t('api.exceptions.not_found') unless item

      item
    end
  end
end
