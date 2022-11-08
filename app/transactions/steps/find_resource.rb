# frozen_string_literal: true

module Steps
  # Finds resource based on :id attribute and resource class. Returns resource object and the rest of the attributes.
  class FindResource
    include Dry::Monads[:result]

    attr_reader :resource_class

    def initialize(resource_class)
      @resource_class = resource_class
    end

    def call(id:, **attributes)
      resource = query_service.find_by id: id
      raise Valkyrie::Persistence::ObjectNotFoundError unless resource.is_a?(resource_class)
      Success(resource: resource, **attributes)
    rescue Valkyrie::Persistence::ObjectNotFoundError => e
      Failure[:resource_not_found, e]
    end

    private

    def query_service
      Valkyrie::MetadataAdapter.find(:postgres).query_service
    end
  end
end
