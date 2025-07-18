# frozen_string_literal: true

# Job to migrate `access` derivatives to `iiif_image` for an item containing image-based derivatives.
#
# Careful considerations were made to ensure this job is idempotent. If the iiif_image generation for one
# assets fails, this job could be re-run to finish the migration.
class MigrateAccessToIIIFImageDerivativeJob
  include Sidekiq::Job

  sidekiq_options queue: :medium

  def perform(item_id)
    item = query_service.find_by id: item_id

    return if item.assets.none?(&:image?) # Return if none of the assets are image assets

    generate_iiif_images(item)
    regenerate_iiif_manifests(item)
    remove_access_files(item)
  end

  private

  # Regenerate IIIF images for each asset. Skips any assets that already have an `iiif_image` derivative.
  def generate_iiif_images(item)
    item.assets.each do |asset|
      next if asset.iiif_image

      result = AddIIIFImageDerivative.new.call(id: asset.id.to_s, updated_by: Settings.system_user)

      raise "Error migrating to iiif_image derivative for #{asset.id}" if result.failure?
    end
  end

  # Regenerate IIIF Manifests if item is published.
  def regenerate_iiif_manifests(item)
    return unless item.published # Skip regenerating iiif manifest if item is not published

    iiif_manifest_result = GenerateIIIFManifests.new.call(id: item.id.to_s, updated_by: Settings.system_user)

    raise 'Error regenerating IIIF manifest' if iiif_manifest_result.failure?
  end

  # Remove `access` files from storage.
  def remove_access_files(item)
    item.asset_ids.each do |asset_id|
      shrine = Valkyrie::StorageAdapter.find(:iiif_derivatives).shrine

      path = "#{asset_id}/access"

      next unless shrine.exists?(path) # Check to see if file is in aws storage

      shrine.delete(path) # Delete access file.
    end
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
