# frozen_string_literal: true

module Resource
  module Steps
    def set_updated_by(*args)
      SetUpdatedBy.new.call(*args)
    end

    def validate(*args)
      Validate.new.call(*args)
    end

    def save(*args)
      Save.new.call(*args)
    end
  end
end