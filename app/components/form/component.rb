# frozen_string_literal: true

module Form
  # Renders a form element. Has slots for inputs, a submit button and an error message. If desired,
  # inputs can be grouped in sections.
  class Component < ViewComponent::Base
    renders_many :inputs, types: {
      text: ->(system_arguments) { Input::Component.new(type: :text, **system_arguments) },
      select: ->(system_arguments) { Input::Component.new(type: :select, **system_arguments) },
      hidden: ->(system_arguments) { Input::Component.new(type: :hidden, **system_arguments) },
      textarea: ->(system_arguments) { Input::Component.new(type: :textarea, **system_arguments) },
      file: ->(system_arguments) { Input::Component.new(type: :file, **system_arguments) },
      readonly: ->(system_arguments) { Input::Component.new(type: :readonly, **system_arguments) }
    }

    renders_many :sections, Section::Component

    renders_one :error, ErrorMessage::Component

    renders_one :submit, SubmitButton::Component

    # Requires name, url and method, any additional arguments will be passed to the form_tag helper.
    #
    # Often times a `:method` parameter should be provided. If the form contains file inputs a truthy
    # `:multipart` parameter should be provided.
    #
    # @param [String] name given to form, passed to backend to identify form
    # @param [String] url for request
    # @param [Hash] options (see ActionView::Helpers::FormTagHelper.form_tag)
    def initialize(name:, url:, **options)
      @name = name
      @url = url
      @options = options
    end
  end
end
