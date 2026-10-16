# frozen_string_literal: true

module Resource
  module Steps
    # Finds Resource.
    class FindResource
      include Dry::Monads[:result]

      attr_reader :resource_class

      def initialize(resource_class)
        @resource_class = resource_class
      end

      # Finds resource based on the id and resource class. Returns resource object and the rest of the attributes.
      #
      # @param id [String] UUID
      def call(id)
        resource = query_service.find_by id: id

        raise Valkyrie::Persistence::ObjectNotFoundError unless resource.is_a?(resource_class)

        Success(resource)
      rescue Valkyrie::Persistence::ObjectNotFoundError => e
        Failure(error: :resource_not_found, exception: e)
      end

      private

      def query_service
        Valkyrie::MetadataAdapter.find(:postgres).query_service
      end
    end
  end
end
