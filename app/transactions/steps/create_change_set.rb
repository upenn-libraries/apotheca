# frozen_string_literal: true

module Steps
  # Creates appropriate change set based on resource and change set classes provided. If a resource is
  # not provided a blank one is created based off `resource_classs`.
  class CreateChangeSet
    include Dry::Monads[:result]

    attr_reader :resource_class, :change_set_class

    def initialize(resource_class, change_set_class)
      @resource_class = resource_class
      @change_set_class = change_set_class
    end

    def call(resource: nil, **attributes)
      resource ||= resource_class.new
      change_set = change_set_class.new(resource)

      begin
        change_set.validate(attributes)
        Success(change_set)
      rescue StandardError => e
        Failure[:error_creating_change_set, e]
      end
    end
  end
end
