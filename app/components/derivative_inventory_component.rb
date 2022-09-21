# frozen_string_literal: true

# Show information about generated derivatives for an Asset
class DerivativeInventoryComponent < ViewComponent::Base
  attr_reader :asset

  # @param [AssetResource] asset
  def initialize(asset:)
    @asset = asset
  end

  # @return [Array<DerivativeResource>]
  def derivatives
    @asset.derivatives
  end

  # @param [DerivativeResource] derivative
  # @return [ActiveSupport::SafeBuffer]
  def derivative_link(derivative:)
    case derivative.type.to_sym
    when :thumbnail
      link_to('Thumbnail', file_asset_path(@asset, type: :thumbnail, disposition: :inline),
              class: 'stretched-link')
    when :access
      link_to('Access', file_asset_path(@asset, type: :access, disposition: :inline),
              class: 'stretched-link')
    else
      derivative.type.titleize
    end
  end

  # @return [ActiveSupport::SafeBuffer]
  def call
    content_tag :div, class: 'card' do
      content_tag(:div, 'Derivatives', class: 'card-header') +
        content_tag(:ul, class: 'list-group list-group-flush') do
          derivatives.map do |d|
            content_tag :li, derivative_link(derivative: d), class: 'list-group-item'
          end.join.html_safe
        end
    end
  end
end
