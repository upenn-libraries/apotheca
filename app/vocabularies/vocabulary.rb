# frozen_string_literal: true

# Base class for building Vocabularies
class Vocabulary
  module Types
    # Data objects available for use in Vocabulary subclasses
    Term = Data.define :label, :uri
  end

  # Dynamic lookup for use in child classes
  # @param [String|Symbol] field
  # @param [Object] value
  # @return [Object]
  def self.find_by(field, value)
    term_name = constants(false).find do |constant_name|
      const = const_get(constant_name)
      next unless const.respond_to?(field.to_sym)

      const.public_send(field.to_sym) == value
    end
    return nil unless term_name

    const_get term_name
  end
end
