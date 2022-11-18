# frozen_string_literal: true

module Header
  class Component < ViewComponent::Base
    renders_one :title, ->(tag: :h1, &block) do
      content_tag tag, &block
    end

    renders_one :right_link, ->(href:, &block) do
      content_tag :a, href: href, class: 'btn btn-primary', &block
    end
  end
end
