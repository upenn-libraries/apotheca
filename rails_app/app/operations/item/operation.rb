# frozen_string_literal: true

module Item
  # Parent class for Item Operations. Includes reuseable steps for Item operations.
  class Operation < Resource::Operation
    alias find_item find_resource
    alias delete_item delete_resource

    def resource_class
      ItemResource
    end

    def change_set_class
      ItemChangeSet
    end

    def derivative_generator_class
      DerivativeService::Item::Derivatives
    end

    def all_derivative_types
      ItemResource::DERIVATIVE_TYPES
    end

    # @param endpoint [PublishingEndpoint]
    # @return [Faraday::Connection]
    def publishing_connection(endpoint)
      Faraday.new(endpoint.host, request: { timeout: 120 }) do |conn|
        conn.request :authorization, 'Token', "token=#{endpoint.token}"
        conn.request :json
        conn.request :retry, exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed],
                             methods: %i[get post patch delete], interval: 10, max: 5
        conn.response :raise_error, include_request: true
        conn.response :json
      end
    end

    def update_ark_metadata_later(*args)
      Steps::UpdateArkMetadataLater.new.call(*args)
    end

    def set_thumbnail(*args)
      Steps::SetThumbnail.new.call(*args)
    end

    def send_unpublish_request(*args)
      Steps::SendUnpublishRequest.new.call(*args)
    end
  end
end
