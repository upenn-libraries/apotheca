# frozen_string_literal: true

module Steps
  # Generates the derivatives types configured using the DerivativeService class provided.
  class GenerateDerivatives
    include Dry::Monads[:result]

    attr_reader :derivative_class, :types, :replace_all

    # @param derivative_class [Class] derivative generator class
    # @param types [Array<Symbol>] list of derivatives to create
    # @param replace_all [Boolean] if derivatives created should replace all present derivatives
    def initialize(derivative_class, types, replace_all: true)
      @derivative_class = derivative_class
      @types = Array.wrap(types)
      @replace_all = replace_all
    end

    def call(change_set)
      derivatives = derivatives_for(change_set)
      derivatives += change_set.resource.derivatives.reject { |d| types.include?(d.type.to_sym) } unless replace_all

      change_set.derivatives = derivatives

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
        begin
          derivative_file = derivative_generator.send(type)

          next if derivative_file.nil? # Skip if no derivative was created

          # Save file to storage, create derivative resource and clean up derivative file.
          storage = find_storage(derivative_file)
          file = storage.upload(file: derivative_file, resource: change_set.resource,
                                original_filename: type.to_s, content_type: derivative_file.mime_type)
          size = derivative_file.size
        ensure
          derivative_file&.cleanup!
        end
        DerivativeResource.new(file_id: file.id, mime_type: derivative_file.mime_type, size: size,
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
