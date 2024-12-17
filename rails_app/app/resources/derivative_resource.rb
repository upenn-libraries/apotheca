# frozen_string_literal: true

# This is a derivative of an original image
class DerivativeResource < Valkyrie::Resource
  attribute :type, Valkyrie::Types::Strict::String
  # Not using a strict type b/c nested dates aren't correctly parsed in the Valkyrie Solr Adapter.
  attribute :generated_at, Valkyrie::Types::DateTime
  attribute :mime_type, Valkyrie::Types::Strict::String
  attribute :size, Valkyrie::Types::Strict::Integer.optional # Size in Bytes
  attribute :file_id, Valkyrie::Types::ID
  attribute :stale, Valkyrie::Types::Strict::Bool

  # Methods to check what type of derivative this is.
  (AssetChangeSet::DERIVATIVE_TYPES + ItemChangeSet::DERIVATIVE_TYPES).each do |symbol|
    define_method "#{symbol}?" do
      symbol == type
    end
  end

  def extension
    MIME::Types[mime_type].first&.preferred_extension
  end
end
