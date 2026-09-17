# frozen_string_literal: true

module Resource
  module Steps
    # Creates appropriate change set based on resource and change set classes provided. If a resource is
    # not provided a blank one is created based off `resource_class`.
    class CreateChangeSet
      include Dry::Monads[:result]

      attr_reader :resource_class, :change_set_class

      # @param resource_class [Class] resource class to use when a blank resource needs to be created
      # @param change_set_class [Class] change_set class to use when creating change_set
      def initialize(resource_class, change_set_class)
        @resource_class = resource_class
        @change_set_class = change_set_class
      end

      # @param resource [Valkyrie::Resource]
      # @param attributes [Hash] attributes to be used when creating change_set (can provide any valid attributes)
      def call(resource: nil, **attributes)
        resource = resource_class.new if resource.nil?
        change_set = change_set_class.new(resource)

        begin
          change_set.validate(attributes)
          Success(change_set)
        rescue StandardError => e
          Failure(error: :error_creating_change_set, exception: e)
        end
      end
    end
  end
end
