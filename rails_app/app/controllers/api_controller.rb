# frozen_string_literal: true

# Shared behavior for JSON-rendering controllers
class APIController < ApplicationController
  class ResourceNotFound < StandardError; end
  class FileNotFound < StandardError; end
  class NotPublishedError < StandardError; end
  class ResourceMismatchError < StandardError; end
  class MissingIdentifierError < StandardError; end
  class InvalidParameterError < StandardError; end
  # class NotAuthorizedError < StandardError; end

  API_FAILURES = {
    ResourceNotFound => :not_found,
    FileNotFound => :not_found,
    NotPublishedError => :not_found,
    InvalidParameterError => :bad_request,
    ResourceMismatchError => :bad_request,
    MissingIdentifierError => :bad_request
  }.freeze

  rescue_from(StandardError, with: :error_response)
  rescue_from(*API_FAILURES.keys, with: :failure_response)

  private

  # @param exception [Exception]
  def failure_response(exception)
    status = API_FAILURES[exception.class] || API_FAILURES.find { |klass, _| exception.is_a?(klass) }&.last
    render json: { status: :fail, message: exception.message }, status: status
  end

  # @param exception [Exception]
  def error_response(exception)
    render json: { status: :error, message: exception.message }, status: :internal_server_error
  end

  # @param identifier [String] uuid of resource to retrieve
  def find(identifier:)
    query_service.find_by id: identifier
  rescue Valkyrie::Persistence::ObjectNotFoundError
    raise ResourceNotFound, I18n.t('api.exceptions.not_found') # Raise our own exception so we can set a message
  end

  # @return [Valkyrie::Persistence::Postgres::QueryService]
  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  # Redirects to an AWS pre-signed URLs to view/download file.
  #
  # Defaults to inline disposition because this allows the browser to choose the best course of action
  # based on its capabilities. This should allow us to support embedding images and allowing for downloads.
  #
  # @param [Valkyrie::Types::ID] file_id identifier for file that contains storage location
  # @param [String] filename to use when serving up file
  def redirect_to_presigned_url(file_id, filename)
    shrine = Valkyrie::StorageAdapter.adapter_for(id: file_id).shrine
    key = file_id.id.split('://').last

    content_disposition = "inline; filename=\"#{filename}\""
    signer = Aws::S3::Presigner.new(client: shrine.client)
    url = signer.presigned_url(:get_object, bucket: shrine.bucket.name, key: key, expires_in: 300,
                                            response_content_disposition: content_disposition)

    redirect_to url, status: :temporary_redirect
  end

  # Redirects to a JSON file from storage (useful for returning generated IIIF manifests from storage)
  #
  # @param [Valkyrie::ID] file_id identifier for file that contains storage location
  def serve_json(file_id)
    manifest_file = Valkyrie::StorageAdapter.find_by id: file_id

    send_data manifest_file.read, type: 'application/json', disposition: :inline
  end

  # Redirect to IIIF image server.
  #
  # @param asset [AssetResource]
  # @param size [String] dimensions of image in valid IIIF format (ex. `w,h`)
  def redirect_to_iiif_image_server(asset, size)
    # @note These links will change once we migrate over to using an iiif_image derivative.
    redirect_to "#{Settings.image_server.url}/iiif/3/#{asset.id}%2Faccess/full/#{size}/0/default.jpg",
                status: :temporary_redirect
  end
end
