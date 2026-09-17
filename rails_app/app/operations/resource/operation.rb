# frozen_string_literal: true

module Resource
  # Parent class for resource operations.
  #
  # Includes steps that can be shared across resources. Define `resource_class` and `change_set_class` in
  # subclasses to use all available steps.
  class Operation < Dry::Operation
    def resource_class
      raise NotImplemented
    end

    def change_set_class
      raise NotImplemented
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

    def validate(*args)
      Steps::Validate.new.call(*args)
    end

    def save(*args)
      Steps::Save.new.call(*args)
    end
  end
end
