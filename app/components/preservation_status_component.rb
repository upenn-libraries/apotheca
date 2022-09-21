# frozen_string_literal: true

# Render a badge showing preservation status of an Asset
class PreservationStatusComponent < ViewComponent::Base
  attr_reader :asset

  # @param [AssetResource] asset
  def initialize(asset:)
    @asset = asset
  end

  # @return [TrueClass, FalseClass]
  def preserved?
    asset.preservation_copies_ids.any?
  end

  # @return [Array<String (frozen)>]
  def badge_status_classes
    preserved? ? ['bg-success'] : %w[bg-warning text-dark]
  end

  # @return [String (frozen)]
  def badge_text
    preserved? ? 'Preserved' : 'Not Preserved'
  end

  # @return [ActiveSupport::SafeBuffer]
  def call
    content_tag :span, badge_text, class: badge_status_classes.push('badge')
  end
end
