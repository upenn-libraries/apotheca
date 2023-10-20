# frozen_string_literal: true

module Steps
  # Step to generate the iiif manifest for an item even if there is one present. The IIIF manifest is saved to storage.
  class GenerateIIIFManifest
    include Dry::Monads[:result]

    # @param [ItemChangeSet] change_set
    def call(change_set)
      # TODO: need to check that all images have derivatives, raise error if there are missing derivatives

      manifest = IIIFService::ManifestGenerator.new(change_set.resource).v2_manifest

      unless manifest.nil?
        # TODO: save to file
      end

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_generating_iiif_manifest, exception: e, change_set: change_set)
    end
  end
end
