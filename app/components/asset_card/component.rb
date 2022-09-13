# frozen_string_literal: true

module AssetCard
  # ViewComponent
  class Component < ViewComponent::Base
    attr_reader :asset

    # @param [AssetResource] asset
    # @param [Integer] index
    def initialize(asset:, index: nil)
      @asset = asset
      @index = index ? index + 1 : nil
    end

    # @return [Array<AssetResource::Annotation>]
    def annotations
      @asset.annotations
    end

    # @return [String]
    def thumbnail_path
      file_asset_path @asset, type: :thumbnail, disposition: :inline
    end

    # @return [ActiveSupport::SafeBuffer]
    def preservation_download_link
      link_to('Download Preservation File',
              file_asset_path(@asset, type: :preservation, disposition: 'attachment'),
              class: 'stretched-link')
    end

    # @return [ActiveSupport::SafeBuffer]
    def access_download_link
      link_to('Download Access Copy',
              file_asset_path(@asset, type: :access, disposition: 'attachment'),
              class: 'stretched-link')
    end
  end
end
