# frozen_string_literal: true
class TermResource < Valkyrie::Resource
  attribute :label, Valkyrie::Types::String
  attribute :uri, Valkyrie::Types::URI
end