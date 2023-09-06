# frozen_string_literal: true

# Parent class for all change_sets
class ChangeSet < Valkyrie::ChangeSet
  # Recursively removes empty values from nested array and hashes.
  def compact_value(value)
    if value.is_a? Array
      value.map { |v| compact_value(v) }.compact_blank
    elsif value.is_a? Hash
      value.transform_values! { |v| compact_value(v) }.compact_blank
    else
      value
    end
  end
end