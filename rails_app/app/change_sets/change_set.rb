# frozen_string_literal: true

# Parent class for all change_sets
class ChangeSet < Valkyrie::ChangeSet
  # Recursively removes empty values from nested array and hashes. Additionally converts empty string values to nil.
  def compact_value(value)
    case value
    when Array
      value.map { |v| compact_value(v) }.compact_blank
    when Hash
      value.transform_values! { |v| compact_value(v) }.compact_blank
    when String
      value.blank? ? nil : value
    else
      value
    end
  end
end