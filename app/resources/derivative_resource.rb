# frozen_string_literal: true

class DerivativeResource < Valkyrie::Resource
  attribute :type, Valkyrie::Types::String
  attribute :generated_at, Valkyrie::Types::DateTime
  attribute :mime_type, Valkyrie::Types::String
  attribute :file_id, Valkyrie::Types::ID
end