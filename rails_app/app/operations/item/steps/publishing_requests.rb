# frozen_string_literal: true

module Item
  module Steps
    # Contains steps to send un/publish requests to publishing endpoint
    class PublishingRequests
      include Dry::Monads[:result]

      UNPUBLISH = 'unpublish'
      PUBLISH = 'publish'
      REQUIRED_PUBLISH_ATTRIBUTES = %i[first_published_at last_published_at published].freeze
      MISSING_PUBLISH_ATTRIBUTES = 'Required publishing attributes missing'

      # @param item [ItemChangeSet, ItemResource]
      def publish(item, endpoint = PublishingEndpoint.digital_collections)
        return Failure(error: :error_publishing_item, message: MISSING_PUBLISH_ATTRIBUTES) unless publishable?(item)

        connection(endpoint)
          .post(endpoint.webhook_path, { event: PUBLISH, data: { item: serialize(item) } })
        Success(item)
      rescue Faraday::ClientError, Faraday::ServerError => e # Raising error if publishing request failed
        Failure(error: :error_publishing_item, message: "Request to publishing endpoint failed: #{error_message(e)}",
                exception: e)
      rescue StandardError => e
        Failure(error: :error_publishing_item, exception: e)
      end

      # @param item [ItemChangeSet, ItemResource]
      # @param endpoint [PublishingEndpoint]
      def unpublish(item, endpoint = PublishingEndpoint.digital_collections)
        connection(endpoint).post(endpoint.webhook_path, { event: UNPUBLISH, data: { item: { id: item.id.to_s } } })
        Success(item)
      rescue Faraday::ResourceNotFound
        # Not raising error when attempting to unpublish an item that hasn't been published.
        Success(item)
      rescue Faraday::ClientError, Faraday::ServerError => e
        Failure(error: :error_unpublishing_item, message: "Request to publishing endpoint failed: #{error_message(e)}",
                exception: e)
      rescue StandardError => e
        Failure(error: :error_unpublishing_item, exception: e)
      end

      private

      # @param item [ItemResource, ItemChangeSet]
      # @return [Boolean]
      def publishable?(item)
        REQUIRED_PUBLISH_ATTRIBUTES.all? { |attribute| item.send(attribute).present? }
      end

      # @param item [ItemResource, ItemChangeSet]
      def serialize(item)
        controller = ApplicationController.renderer.with_defaults(http_host: Settings.api_url, https: true)
        rendered_json = controller.render('api/resources/items/_item',
                                          locals: { params: { assets: 'true' } },
                                          assigns: { item: item.presenter })
        JSON.parse(rendered_json)
      end

      # @param error [Exception]
      # @return [String]
      def error_message(error)
        error.response_body&.dig('message') || error.msg
      end

      # @param endpoint [PublishingEndpoint]
      # @return [Faraday::Connection]
      def connection(endpoint)
        Faraday.new(endpoint.host, request: { timeout: 120 }) do |conn|
          conn.request :authorization, 'Token', "token=#{endpoint.token}"
          conn.request :json
          conn.request :retry, exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed],
                               methods: %i[get post patch delete], interval: 10, max: 5
          conn.response :raise_error, include_request: true
          conn.response :json
        end
      end
    end
  end
end
