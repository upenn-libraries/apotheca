# frozen_string_literal: true

module Form
  # Renders a form element. Has slots for inputs, a submit button and an error message. If desired,
  # inputs can be grouped in sections.
  class Component < ViewComponent::Base
    renders_many :inputs, types: {
      text: ->(system_arguments) { Input::Component.new(type: :text, **system_arguments) },
      select: ->(system_arguments) { Input::Component.new(type: :select, **system_arguments) }
    }

    renders_many :sections, Section::Component

    renders_one :error, ErrorMessage::Component

    renders_one :submit, SubmitButton::Component

    def initialize(name:, url:, method:)
      @name = name
      @url = url
      @method = method
    end
  end
end
