# frozen_string_literal: true

module Modal
  # Modal and button component
  class Component < ViewComponent::Base
    def initialize(title:, id:, button_variant: :primary, **options)
      @id = id
      @title = title
      @button_classes = ['btn', "btn-#{button_variant}"]
      @modal_classes = configure_modal(options)
    end

    private

    def configure_modal(attributes)
      classes = []
      classes << 'modal-dialog-scrollable' if attributes[:scrollable]
      classes << "modal-#{attributes[:modal_size]}" if attributes[:modal_size]
      classes
    end
  end
end
