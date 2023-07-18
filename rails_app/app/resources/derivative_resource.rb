# frozen_string_literal: true

# This is a derivative of an original image
class DerivativeResource < Valkyrie::Resource
  attribute :type, Valkyrie::Types::Strict::String
  attribute :generated_at, Valkyrie::Types::Strict::DateTime
  attribute :mime_type, Valkyrie::Types::Strict::String
  attribute :file_id, Valkyrie::Types::ID
  attribute :stale, Valkyrie::Types::Strict::Bool

  def method_missing(symbol, *_args)
    raise NoMethodError unless respond_to_missing? symbol

    type == symbol.to_s[...-1]
  end

  def respond_to_missing?(symbol, _include_private = false)
    return false unless symbol.to_s[...-1].in? AssetChangeSet::AssetDerivativeChangeSet::TYPES

    symbol.to_s.end_with? '?'
  end
end
