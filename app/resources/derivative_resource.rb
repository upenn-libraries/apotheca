# frozen_string_literal: true

# This is a derivative of an original image
class DerivativeResource < Valkyrie::Resource
  attribute :type, Valkyrie::Types::String
  attribute :generated_at, Valkyrie::Types::DateTime
  attribute :mime_type, Valkyrie::Types::String
  attribute :file_id, Valkyrie::Types::ID

  def method_missing(symbol, *_args)
    raise NoMethodError unless respond_to_missing? symbol

    type == symbol.to_s[...-1]
  end

  def respond_to_missing?(symbol, _include_private = false)
    return false unless symbol.to_s[...-1].in? AssetChangeSet::AssetDerivativeChangeSet::TYPES

    symbol.to_s.end_with? '?'
  end
end
