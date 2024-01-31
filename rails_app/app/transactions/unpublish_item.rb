# frozen_string_literal: true

# Transaction that unpublishes an Item.
class UnpublishItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'item_resource.create_change_set'
  step :unpublish
  step :save, with: 'change_set.save'
  tee :record_event

  def unpublish(change_set)
    change_set.published = false

    unpublish_request(change_set)

    Success(change_set)
  rescue StandardError => e
    Failure(error: :error_unpublishing_item, exception: e, change_set: change_set)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :unpublish_item)
  end

  private

  def unpublish_request(change_set)
    connection = Faraday.new(Settings.publish.url) do |conn|
      conn.request :authorization, 'Token', "token=#{Settings.publish.token}"
      conn.request :json
      conn.request :retry
      conn.response :json
    end

    response = connection.delete("items/#{change_set.unique_identifier}")

    # Raise error if publishing request is not successful
    raise "Request to publishing endpoint failed: Not Found" if response.status == 404
    raise "Request to publishing endpoint failed: #{response.body['error']}" unless response.success?
  end
end
