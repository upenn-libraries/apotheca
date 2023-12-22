# frozen_string_literal: true

# This is a derivative of an original image
class DerivativeResource < Valkyrie::Resource
  attribute :type, Valkyrie::Types::Strict::String
  attribute :generated_at, Valkyrie::Types::Strict::DateTime
  attribute :mime_type, Valkyrie::Types::Strict::String
  attribute :file_id, Valkyrie::Types::ID
  attribute :stale, Valkyrie::Types::Strict::Bool

  # Methods to check what type of derivative this is.
  (AssetChangeSet::AssetDerivativeChangeSet::TYPES + ItemChangeSet::ItemDerivativeChangeSet::TYPES).each do |symbol|
    define_method "#{symbol}?" do
      symbol == type
    end
  end
end
