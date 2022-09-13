# frozen_string_literal: true

# This is a derivative of an original image
class DerivativeResource < Valkyrie::Resource
  attribute :type, Valkyrie::Types::String
  attribute :generated_at, Valkyrie::Types::DateTime
  attribute :mime_type, Valkyrie::Types::String
  attribute :file_id, Valkyrie::Types::ID

  # @return [TrueClass, FalseClass]
  def thumbnail?
    type == AssetChangeSet::AssetDerivativeChangeSet::THUMBNAIL_TYPE
  end

  # @return [TrueClass, FalseClass]
  def access?
    type == AssetChangeSet::AssetDerivativeChangeSet::ACCESS_TYPE
  end
end
