# frozen_string_literal: true

module PublishingService
  # Client to make request to publish and unpublish records from consumer applications.
  #
  # Consumer applications are expected to have an endpoint that responds to POST request. The request will
  # contain a JSON body with the event and data. The JSON body will have two keys "event" and "data". Valid events are
  # "publish" and "unpublish". The "data" key will contain a hash with the resource information. Below is an example:
  #    { "event": "publish", "data": { "item": { "id": "" } } }
  class Client
    class Error < StandardError; end

    PUBLISH = 'publish'
    UNPUBLISH = 'unpublish'

    attr_reader :endpoint, :connection

    # @param [PublishingService::Endpoint] endpoint
    def initialize(endpoint)
      @endpoint = endpoint
      @connection = create_connection(endpoint.host, endpoint.token)
    end

    # Publish record. Sends request to external application to add/update a record (item).
    #
    # @param [ItemChangeSet] change_set
    def publish(change_set)
      connection.post(endpoint.webhook_path, { event: PUBLISH, data: { item: serialize(change_set) } })
    rescue Faraday::ClientError, Faraday::ServerError => e # Raising error if publishing request failed
      raise Error, "Request to publishing endpoint failed: #{e.response[:body]['error']}"
    end

    # Unpublish record. Send request to external application to remove record (item).
    #
    # @param [ItemChangeSet|ItemResource] change_set
    def unpublish(change_set)
      connection.post(endpoint.webhook_path, { event: UNPUBLISH, data: { item: { id: change_set.id.to_s } } })
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

    def serialize(change_set)
      json_string = ApplicationController.renderer.render('api/resources/items/_item',
                                                          locals: { params: { assets: 'true' } },
                                                          assigns: { item: change_set })
      JSON.parse(json_string)
    end
  end
end
