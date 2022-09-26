# frozen_string_literal: true

module AssetInfo
  # ViewComponent
  class Component < ViewComponent::Base
    attr_reader :asset, :item, :index

    # @param [AssetResource] asset
    # @param [ItemResource] item
    # @param [Integer] index
    def initialize(asset:, item:, index: nil)
      @asset = asset
      @index = index ? index + 1 : nil
      @item = item
    end

    # @return [String]
    def asset_title
      [index, asset.original_filename, asset.label].compact.join(' - ')
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
              file_asset_path(@asset, type: :preservation, disposition: :attachment),
              class: 'stretched-link')
    end

    # @return [ActiveSupport::SafeBuffer]
    def access_download_link
      link_to('Download Access Copy',
              file_asset_path(@asset, type: :access, disposition: 'attachment'),
              class: 'stretched-link')
    end

    # @return [String]
    def size
      number_to_human_size asset.technical_metadata.size
    end

    # @return [String]
    def mime_type
      asset.technical_metadata.mime_type
    end
  end
end
