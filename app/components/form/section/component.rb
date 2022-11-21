# frozen_string_literal: true

module Form
  module Section
    # Component to define a section of a form.
    class Component < ViewComponent::Base
      renders_one :title, ->(&block) { content_tag :h4, &block }

      renders_many :inputs, types: {
        text: ->(system_arguments) { Input::Component.new(type: :text, **system_arguments) },
        select: ->(system_arguments) { Input::Component.new(type: :select, **system_arguments) },
        hidden: ->(system_arguments) { Input::Component.new(type: :hidden, **system_arguments) },
        textarea: ->(system_arguments) { Input::Component.new(type: :textarea, **system_arguments) }
      }
    end
  end
end
