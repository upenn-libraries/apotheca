# frozen_string_literal: true

module AssetCard
  # ViewComponent
  class Component < ViewComponent::Base
    attr_reader :asset, :index

    # @param [AssetResource] asset
    # @param [Integer] index
    # @param [TrueClass, FalseClass] arranged
    def initialize(asset:, arranged: false, index: nil)
      @asset = asset
      @index = index ? index + 1 : nil
      @arranged = arranged
    end

    # @return [String]
    def card_title
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
              file_asset_path(@asset, type: :preservation, disposition: 'attachment'),
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

    # @return [TrueClass, FalseClass]
    def arranged?
      @arranged
    end
  end
end
