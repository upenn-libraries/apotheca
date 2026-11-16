# frozen_string_literal: true

module Item
  module Steps
    # Creates faraday connection to external application where items are published
    class CreatePublishingConnection
      include Dry::Monads[:result]

      def call(endpoint)
        @connection ||= Faraday.new(endpoint.host, request: { timeout: 120 }) do |conn|
          conn.request :authorization, 'Token', "token=#{endpoint.token}"
          conn.request :json
          conn.request :retry, exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed],
                               methods: %i[get post patch delete], interval: 10, max: 5
          conn.response :raise_error, include_request: true
          conn.response :json
        end
        Success(@connection)
      rescue StandardError => e
        Failure(error: :error_establishing_publishing_connection, exception: e, endpoint: endpoint)
      end
    end
  end
end
