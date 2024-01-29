# frozen_string_literal: true

# Transaction that publishes an item
class PublishItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'item_resource.create_change_set'
  step :generate_iiif_manifest, with: 'item_resource.generate_derivatives'
  step :publish
  step :save, with: 'change_set.save'
  tee :record_event

  def publish(change_set)
    add_published_values(change_set)

    payload = create_payload(change_set)

    publish_request(payload)

    Success(change_set)
  rescue StandardError => e
    Failure(error: :error_publishing_item, exception: e, change_set: change_set)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :publish_item)
  end

  private

  def publish_request(payload)
    # TODO: if request errors our try again at least two additional times?
    response = Faraday.post(Settings.publish.url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Token token=#{Settings.publish.token}"
      req.body = payload.to_json
    end

    # Raise error if publishing request is not successful
    raise "Request to publishing endpoint failed: #{response.body.error}" unless response.success?
  end

  # Creates payload to send to publishing endpoint
  #
  # @return [Hash]
  def create_payload(change_set)
    resource = change_set.resource

    # Create payload to send to Colenda
    payload = {
      item: {
        id: resource.unique_identifier.to_s,
        uuid: resource.id,
        first_published_at: change_set.first_published_at.utc.iso8601,
        last_published_at: change_set.last_published_at.utc.iso8601,
        descriptive_metadata: resource.presenter.descriptive_metadata.to_h,
        iiif_manifest_path: change_set.derivatives.find { |d| d.type == 'iiif_manifest' }&.file_id.to_s.split('://').last,
        assets: assets(resource)
      }
    }

    # Only send thumbnail_asset_id if a thumbnail image is present.
    payload[:item][:thumbnail_asset_id] = resource.thumbnail_asset_id.to_s if resource.thumbnail_image?
    payload
  end

  def assets(resource)
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
          mime_type: asset.thumbnail.mime_type
        }
      end

      # Only provide asset if its not a iiif-compatible file
      if asset.access && !asset.image?
        hash[:access_file] = {
          path: asset.access.file_id.to_s.split('://').last,
          mime_type: asset.access.mime_type
        }
      end

      hash
    end
  end

  def add_published_values(change_set)
    publishing_at = DateTime.current

    change_set.first_published_at = publishing_at if change_set.first_published_at.blank?
    change_set.last_published_at = publishing_at
    change_set.published = true
  end
end
