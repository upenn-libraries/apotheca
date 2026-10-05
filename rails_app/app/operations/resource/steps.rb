# frozen_string_literal: true

module Resource
  # Steps that can be shared across resources.
  module Steps
    def set_updated_by(*args)
      SetUpdatedBy.new.call(*args)
    end

    def require_updated_by(*args)
      RequireAttribute.new(:updated_by).call(*args)
    end

    def validate(*args)
      Validate.new.call(*args)
    end

    def save(*args)
      Save.new.call(*args)
    end
  end
end
