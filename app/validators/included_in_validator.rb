# Validates if values are included in specified field.
#
# This is to be used for validating values that should be present in another field before being used in this field.
class IncludedInValidator < ActiveModel::EachValidator
  def check_validity!
    raise ArgumentError, ':with must be supplied' unless options.include?(:with)

    super
  end

  def validate_each(record, attribute, value)
    return if value.blank?
    raise ArgumentError, ':with must be supplied with a valid attribute' unless record.respond_to?(options[:with])
    return if record.send(options[:with]).include?(value)

    record.errors.add(attribute, "is not included in #{options[:with]}")
  end
end