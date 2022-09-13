# frozen_string_literal: true

module AssetCard
  # ViewComponent
  class Component < ViewComponent::Base
    attr_reader :asset

    # @param [AssetResource] asset
    def initialize(asset:)
      @asset = asset
    end

    # @return [Array<AssetResource::Annotation>]
    def annotations
      @asset.annotations
    end

    # @return [DerivativeResource]
    def thumbnail_path
      file_asset_path @asset, type: :thumbnail, disposition: :inline
    end

    def preservation_download_link
      link_to('Download Preservation File',
              file_asset_path(@asset, type: :preservation, disposition: 'attachment'))
    end

    def access_download_link
      link_to('Download Access Copy',
              file_asset_path(@asset, type: :access, disposition: 'attachment'))
    end

  end
end
