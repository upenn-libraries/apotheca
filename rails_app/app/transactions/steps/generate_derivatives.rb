# frozen_string_literal: true

module Steps
  # Generates the derivatives types configured using the DerivativeService class provided.
  class GenerateDerivatives
    include Dry::Monads[:result]

    attr_reader :derivative_class, :types

    def initialize(derivative_class, *types)
      @derivative_class = derivative_class
      @types = Array.wrap(types)
    end

    def call(change_set)
      change_set.derivatives = derivatives_for(change_set.resource)

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_generating_derivatives, exception: e)
    end

    private

    # Generates derivatives for the given resource.
    #
    # @param resource [Valkyrie::Resource]
    # @return [Array<DerivativeResource>]
    def derivatives_for(resource)
      derivative_generator = derivative_class.new(resource)

      types.filter_map do |type|
        derivative_file = derivative_generator.send(type)

        next if derivative_file.nil? # Skip if no derivative was created

        # Save file to storage, create derivative resource and clean up derivative file.
        storage = find_storage(derivative_file)
        file = storage.upload(file: derivative_file, resource: resource,
                              original_filename: type.to_s, content_type: derivative_file.mime_type)
        derivative_file.cleanup!

        DerivativeResource.new(file_id: file.id, mime_type: derivative_file.mime_type,
                               type: type.to_s, generated_at: DateTime.current)
      end
    end

    def find_storage(derivative_file)
      if derivative_file.iiif_image
        iiif_derivative_storage
      elsif derivative_file.iiif_manifest
        iiif_manifest_storage
      else
        derivative_storage
      end
    end

    # @return [Valkyrie::StorageAdapter]
    def iiif_manifest_storage
      Valkyrie::StorageAdapter.find(:iiif_manifests)
    end

    # @return [Valkyrie::StorageAdapter]
    def derivative_storage
      Valkyrie::StorageAdapter.find(:derivatives)
    end

    # @return [Valkyrie::StorageAdapter]
    def iiif_derivative_storage
      Valkyrie::StorageAdapter.find(:iiif_derivatives)
    end
  end
end
