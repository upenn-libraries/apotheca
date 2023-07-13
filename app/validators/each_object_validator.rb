# frozen_string_literal: true

# Validates each object/hash in an array.

class EachObjectValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, values)
    Array.wrap(values).each_with_index do |value, i|
      # Check that each required fields are present.

      Array.wrap(options[:required]).each do |required_key|
        next if value[required_key].present?

        record.errors.add(attribute, "missing #{required_key}")
      end
    end
  end
end
