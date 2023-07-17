# frozen_string_literal: true

# Base class for building Vocabularies
# Define common Data objects here on Types
# Subclasses should list term values as Data objects, e.g.:
# class MyTerms < Vocabulary
#   Heading = Data.define :label, :uri, :active
#   MY_HEADING = Heading['Stuff', 'http://stuff.com/pid/1234', false]
# end
class Vocabulary
  module Types
    # Data objects available for use in Vocabulary subclasses
    Term = Data.define :label, :uri
  end

  # Dynamic lookup of constant values for use in child classes
  # @return [Object]
  # @param [Hash] conditions
  def self.find_by(conditions)
    term_name = constants(false).find do |constant_name|
      const = const_get(constant_name)
      conditions.all? do |k, v|
        return nil unless const.respond_to?(k.to_sym)

        const.public_send(k.to_sym) == v
      end
    end
    return nil unless term_name

    const_get term_name
  end
end
