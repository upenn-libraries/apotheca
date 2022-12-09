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

    # @return [Array<AssetResource::Annotation>]
    def annotations
      @asset.annotations&.map(&:text)
    end

    def thumbnail
      if @asset.thumbnail
        tag :img, src: thumbnail_path, alt: 'Thumbnail for Asset', class: 'img-thumbnail'
      else
        return render(partial: 'shared/no_thumbnail')
      end
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

    def set_as_thumbnail
      classes = ['p-0']
      classes.push('disabled') if @item.is_thumbnail?(@asset.id)

      render(Form::Component.new(name: 'assets', url: item_path(@item), method: :patch)) do |form|
        form.with_input_hidden(label: nil, field: 'item[thumbnail_asset_id]', value: @asset.id)
        form.with_submit('Set as Item Thumbnail', variant: :link, class: classes)
      end
    end

    def thumbnail_badge
      return unless @item.is_thumbnail?(@asset.id)
      tag.span 'Currently Set as Thumbnail', class: 'badge bg-secondary thumbnail-status m-2'
    end

    # @return [String]
    def size
      number_to_human_size asset.technical_metadata.size
    end

    # @return [String]
    def mime_type
      asset.technical_metadata.mime_type
    end

    private

    # @return [String]
    def thumbnail_path
      file_asset_path @asset, type: :thumbnail, disposition: :inline
    end
  end
end
