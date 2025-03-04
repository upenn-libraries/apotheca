# frozen_string_literal: true

module PublishingService
  # Client to make request to publish records (items) to external applications for display.
  #
  # External application are expected to have an endpoint at `/items` that responds to post and deleted.
  #   - POST /items should add the item record to the external system
  #   - DELETE /items/:unique_identifier should remove the item from the external system
  class Client
    class Error < StandardError; end

    attr_reader :endpoint, :connection

    # @param [PublishingService::Endpoint] endpoint
    def initialize(endpoint)
      @endpoint = endpoint
      @connection = create_connection(endpoint.base_url, endpoint.token)
    end

    # Publish record. Sends request to external application to add/update an record (item).
    #
    # @param [ItemChangeSet] change_set
    def publish(change_set)
      connection.post(endpoint.item_path, { item: serialize(change_set) })
    rescue Faraday::ClientError, Faraday::ServerError => e # Raising error if publishing request failed
      raise Error, "Request to publishing endpoint failed: #{e.response[:body]['error']}"
    end

    # Unpublish record. Send request to external application to remove record (item).
    #
    # @param [ItemChangeSet|ItemResource] change_set
    def unpublish(change_set)
      connection.delete("#{endpoint.item_path}/#{change_set.unique_identifier}")
    rescue Faraday::ResourceNotFound
      # Not raising error when attemping to unpublish an item that hasn't been published.
    rescue Faraday::ClientError, Faraday::ServerError => e
      raise Error, "Request to publishing endpoint failed: #{e.response[:body]['error']}"
    end

    private

    # Faraday connection object to use for all requests.
    def create_connection(url, token)
      Faraday.new(url) do |conn|
        conn.request :authorization, 'Token', "token=#{token}"
        conn.request :json
        conn.request :retry, exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed],
                             methods: %i[get post patch delete], interval: 10, max: 5
        conn.response :raise_error, include_request: true
        conn.response :json
      end
    end

    # Serialize change_set into the json payload that is needed for the publish request.
    def serialize(change_set)
      resource = change_set.resource

      # Create payload to send to Colenda
      payload = {
        id: resource.unique_identifier.to_s,
        uuid: resource.id,
        first_published_at: change_set.first_published_at.utc.iso8601,
        last_published_at: change_set.last_published_at.utc.iso8601,
        descriptive_metadata: resource.presenter.descriptive_metadata.to_h,
        iiif_manifest_path: change_set.derivatives.find { |d| d.type == 'iiif_manifest' }&.file_id.to_s.split('://').last,
        pdf_path: change_set.derivatives.find { |d| d.type == 'pdf' }&.file_id.to_s.split('://').last,
        assets: serialize_assets(resource)
      }

      # Only send thumbnail_asset_id if a thumbnail image is present.
      payload[:thumbnail_asset_id] = resource.thumbnail_asset_id.to_s if resource.thumbnail_image?

      payload
    end

    def serialize_assets(resource)
      resource.arranged_assets.map do |asset|
        hash = {
          id: asset.id.to_s,
          filename: asset.original_filename,
          iiif: asset.image?,
          original_file: {
            path: asset.preservation_file_id.to_s.split('://').last,
            size: asset.technical_metadata.size,
            mime_type: asset.technical_metadata.mime_type
          }
        }

        if asset.thumbnail
          hash[:thumbnail_file] = {
            path: asset.thumbnail.file_id.to_s.split('://').last,
            mime_type: asset.thumbnail.mime_type,
            size: asset.thumbnail.size
          }
        end

        # Only provide asset if its not a iiif-compatible file
        if asset.access && !asset.image?
          hash[:access_file] = {
            path: asset.access.file_id.to_s.split('://').last,
            mime_type: asset.access.mime_type,
            size: asset.access.size
          }
        end

        hash
      end
    end
  end
end
