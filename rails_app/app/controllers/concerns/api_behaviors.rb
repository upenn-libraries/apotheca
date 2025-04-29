# frozen_string_literal: true

# Shared behaviors for API controllers
module APIBehaviors
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_user!

    # Seems like the order of precedence here is inverted
    rescue_from(StandardError, with: :error_response)
    rescue_from(*API_FAILURES.keys, with: :failure_response)
  end

  class ResourceNotFound < StandardError; end
  class NotPublishedError < StandardError; end
  class ResourceMismatchError < StandardError; end
  # class NotAuthorizedError < StandardError; end

  API_FAILURES = {
    ResourceNotFound => :not_found,
    NotPublishedError => :not_found,
    ResourceMismatchError => :bad_request
  }.freeze

  private

  # @param exception [Exception]
  def failure_response(exception)
    render json: { status: :fail, message: exception.message }, status: API_FAILURES[exception.class]
  end

  # @param exception [Exception]
  def error_response(exception)
    render json: { status: :error, message: exception.message }, status: :internal_server_error
  end

  # @param identifier [String] uuid of resource to retrieve
  def find(identifier:)
    Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by id: identifier
  rescue Valkyrie::Persistence::ObjectNotFoundError
    raise ResourceNotFound, I18n.t('api.exceptions.not_found') # Raise our own exception so we can set a message
  end
end
