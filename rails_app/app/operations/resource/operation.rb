# frozen_string_literal: true

module Resource
  # Parent class for resource operations.
  #
  # Includes steps that can be shared across resources. Define `resource_class` and `change_set_class` in
  # subclasses to use all available steps.
  class Operation < Dry::Operation
    # Convenience method to use `call` method without instantiating the operation.
    def self.call(...)
      new.call(...)
    end

    def resource_class
      raise NotImplemented
    end

    def change_set_class
      raise NotImplemented
    end

    def derivative_generator_class
      raise NotImplemented
    end

    def all_derivative_types
      raise NotImplemented
    end

    def find_resource(id)
      Steps::FindResource.new(resource_class).call(id)
    end

    def create_change_set(**attributes)
      Steps::CreateChangeSet.new(resource_class, change_set_class).call(**attributes)
    end

    def set_updated_by(*args)
      Steps::SetUpdatedBy.new.call(*args)
    end

    def require_updated_by(*args)
      Steps::RequireAttribute.new(:updated_by).call(*args)
    end

    def generate_derivatives(change_set)
      Steps::GenerateDerivatives.new(derivative_generator_class, all_derivative_types).call(change_set)
    end

    def validate(*args)
      Steps::Validate.new.call(*args)
    end

    def save(*args)
      Steps::Save.new.call(*args)
    end
  end
end
