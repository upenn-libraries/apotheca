# frozen_string_literal: true

module Steps
  class CreateChangeSet
    include Dry::Monads[:result]

    attr_reader :resource_class, :change_set_class

    def initialize(resource_class, change_set_class)
      @resource_class = resource_class
      @change_set_class = change_set_class
    end

    # def call(input, resource: nil)

    def call(resource: nil, **attributes)
      resource = resource_class.new unless resource
      change_set = change_set_class.new(resource)
      change_set.validate(attributes) # TODO: Can this throw an error?
      Success(change_set)
    end
  end
end