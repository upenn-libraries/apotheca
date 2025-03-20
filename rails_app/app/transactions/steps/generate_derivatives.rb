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
      change_set.derivatives = derivatives_for(change_set)

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_generating_derivatives, exception: e)
    end

    private

    # Generates derivatives for the given resource.
    #
    # Note: Derivatives for items are generated from the resource object while derivatives for assets are
    #       generated from the change set. Derivatives for items are generated at the publish step therefore all
    #       the necessary data is present on the resource. Derivatives for assets are generated from the change set
    #       to prevent retrieving the preservation file multiple times.
    #
    # @param change_set [Valkyrie::ChangeSet]
    # @return [Array<DerivativeResource>]
    def derivatives_for(change_set)
      derivative_generator = derivative_class.new(change_set)

      types.filter_map do |type|
        derivative = derivative_generator.send(type)

        next if derivative.nil? # Skip if no derivative was created

        if derivative.is_a? DerivativeService::DerivativeFile
          derivative_resource(derivative, change_set, type)

        elsif derivative.is_a? DerivativeResource
          derivative.type = type.to_s # TODO: don't like this
          derivative
        else
          # raise error?
        end
      end
    end

    # Loads derivative file to storage and creates DerivativeResource object.
    #
    # @param [DerivativeService::DerivativeFile]
    # @return [DerivativeResource]
    def derivative_resource(derivative_file, change_set, type)
      # Save file to storage, create derivative resource and clean up derivative file.
      storage = find_storage(derivative_file)
      file = storage.upload(file: derivative_file, resource: change_set.resource,
                            original_filename: type.to_s, content_type: derivative_file.mime_type)
      size = derivative_file.size

      DerivativeResource.new(file_id: file.id, mime_type: derivative_file.mime_type, size: size,
                             type: type.to_s, generated_at: DateTime.current)
    ensure
      derivative_file.cleanup!
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
