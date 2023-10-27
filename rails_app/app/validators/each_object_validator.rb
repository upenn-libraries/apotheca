# frozen_string_literal: true

# Validates each object/hash in an array. The following validations are supported:
#   - required: ensuring that a required key is present
#   - accepted_values: ensuring that the value provided is included in the list of valid values
class EachObjectValidator < ActiveModel::EachValidator
  REQUIRED = :required
  ACCEPTED_VALUES = :accepted_values
  VALIDATIONS = [REQUIRED, ACCEPTED_VALUES].freeze

  def check_validity!
    options.each do |_field, validations|
      validations.each do |validation, args|
        raise ArgumentError, "#{validation} validation is not supported" unless VALIDATIONS.include?(validation)

        if validation == ACCEPTED_VALUES && !args.is_a?(Array)
          raise ArgumentError, "#{ACCEPTED_VALUES} validation must be provided an array"
        end
      end
    end
  end

  def validate_each(record, attribute, values)
    Array.wrap(values).each do |value|
      options.each do |field, validations|
        validations.each do |validation, args|
          case validation
          when :required
            next if value[field].present?

            record.errors.add(attribute, "missing #{field}")
          when :accepted_values
            next if args.include? value[field]

            record.errors.add(attribute, "#{field} contains invalid value")
          end
        end
      end
    end
  end
end
