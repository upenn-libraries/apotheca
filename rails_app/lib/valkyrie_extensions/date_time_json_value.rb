# frozen_string_literal: true

# Inspired by: https://github.com/psu-libraries/cho/pull/1038/files
#
# Prepended to JSONValueMapper::DateValue class methods to return only DateTime objects when a string is a properly
# encoded iso8601 date with a time and timezone. This fixes issues where strings that are value EDTF dates such
# as '2001-01-01T01:00:00' are not cast to DateTime objects, but are instead retained as strings.

require 'date'
module ValkyrieExtensions
  module DateTimeJSONValue
    def handles?(value)
      return false unless value.is_a?(String)
      return false unless value.match? /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(\+|-)\d{2}:\d{2}/

      ::DateTime.iso8601(value)
    rescue StandardError
      false
    end
  end
end
