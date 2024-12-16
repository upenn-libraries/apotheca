# frozen_string_literal: true

module AssetInfo
  # ViewComponent
  class Component < ViewComponent::Base
    attr_reader :asset, :item, :index, :user

    # @param [AssetResource] asset
    # @param [ItemResource] item
    # @param [User] user
    # @param [Integer] index
    def initialize(asset:, item:, user:, index: nil)
      @asset = asset
      @index = index ? index + 1 : nil
      @item = item
      @user = user
    end

    # @return [Array<AssetResource::Annotation>]
    def annotations
      asset.annotations&.map(&:text)
    end

    def thumbnail
      if asset.thumbnail
        tag.img src: thumbnail_path, alt: 'Thumbnail for Asset', class: 'img-thumbnail', loading: 'lazy'
      else
        render(partial: 'resources/no_thumbnail')
      end
    end

    # @return [ActiveSupport::SafeBuffer]
    def preservation_download_link
      link_to('Download Preservation File',
              file_asset_path(asset, type: :preservation, disposition: :attachment),
              class: 'stretched-link list-group-item list-group-item-action')
    end

    # @return [ActiveSupport::SafeBuffer]
    def access_download_link
      classes = %w[stretched-link list-group-item list-group-item-action]
      classes.push('disabled') unless access_copy?

      link_to('Download Access Copy',
              file_asset_path(asset, type: :access, disposition: 'attachment'),
              class: classes)
    end

    def thumbnail_form_classes
      form_classes = %w[list-group-item list-group-item-action]
      form_classes.push('disabled') if item.thumbnail?(asset.id)

      form_classes
    end

    def thumbnail_submit_classes
      submit_classes = %w[p-0 text-decoration-none link-dark text-wrap text-start]
      submit_classes.push('disabled') if item.thumbnail?(asset.id)

      submit_classes
    end

    def set_as_thumbnail
      render(Form::Component.new(name: 'assets',
                                 model: item,
                                 class: thumbnail_form_classes, label_col: '0', input_col: 'auto')) do |form|
        form.with_field(:thumbnail_asset_id, value: asset.id, type: :hidden)
        form.with_submit('Set as Item Thumbnail',
                         variant: :link,
                         confirm: I18n.t('actions.asset.change_thumbnail.confirm_message'),
                         class: thumbnail_submit_classes,
                         id: 'set-as-item-thumbnail')
      end
    end

    def thumbnail_badge
      return unless item.thumbnail?(asset.id)

      tag.span 'Currently Set as Thumbnail', class: 'badge bg-secondary thumbnail-status align-self-center'
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
      file_asset_path asset, type: :thumbnail, disposition: :inline
    end

    # @return [Boolean]
    def access_copy?
      asset.access.present?
    end
  end
end
