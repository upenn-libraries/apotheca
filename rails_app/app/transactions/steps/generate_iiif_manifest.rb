# frozen_string_literal: true

module Steps
  # Step to generate the iiif manifest for an item even if there is one present. The IIIF manifest is saved to storage.
  class GenerateIIIFManifest
    include Dry::Monads[:result]

    # @param [ItemChangeSet] change_set
    def call(change_set)
      manifest = IIIFService::ManifestGenerator.new(change_set.resource).v2_manifest

      # Save to IIIF manifest to file.
      unless manifest.nil?
        file = iiif_manifest_storage.upload(file: StringIO.new(manifest), resource: change_set.resource,
                                            original_filename: 'iiif_manifest', content_type: 'application/json')
        derivative_resource = DerivativeResource.new(file_id: file.id, mime_type: 'application/json',
                                                     type: 'iiif_manifest', generated_at: DateTime.current)

        change_set.derivatives = [derivative_resource]
      end

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_generating_iiif_manifest, exception: e, change_set: change_set)
    end

    private

    def iiif_manifest_storage
      Valkyrie::StorageAdapter.find(:iiif_manifests)
    end
  end
end
