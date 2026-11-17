# frozen_string_literal: true

module Item
  module Steps
    # Send unpublish request to publishing endpoint
    class SendUnpublishRequest
      include Dry::Monads[:result]

      UNPUBLISH = 'unpublish'

      # @param item [ItemChangeSet, ItemResource]
      # @param endpoint [PublishingEndpoint]
      def call(item, endpoint = PublishingEndpoint.digital_collections)
        connection(endpoint).post(endpoint.webhook_path, { event: UNPUBLISH, data: { item: { id: item.id.to_s } } })
        Success(item)
      rescue Faraday::ResourceNotFound
        # Not raising error when attempting to unpublish an item that hasn't been published.
        Success(item)
      rescue Faraday::ClientError, Faraday::ServerError => e
        message = e.response_body&.dig('message') || e.msg
        Failure(error: :error_unpublishing_item, message: "Request to publishing endpoint failed: #{message}",
                exception: e)
      rescue StandardError => e
        Failure(error: :error_unpublishing_item, exception: e)
      end

      private

      # @param endpoint [PublishingEndpoint]
      # @return [Faraday::Connection]
      def connection(endpoint)
        @connection ||= Operation.new.publishing_connection(endpoint)
      end
    end
  end
end
