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

    renders_many :fields, ->(*field_path, **args, &block) {
      Field::Component.new(*field_path, model: @model, **args, &block)
    }

    renders_many :sections, Section::Component

    renders_one :error, ErrorMessage::Component

    renders_one :submit, SubmitButton::Component

    # Requires name and url. Any additional arguments will be passed to the form_tag helper.
    #
    # Often times a `:method` parameter should be provided. If the form contains file inputs a truthy
    # `:multipart` parameter should be provided.
    #
    # @param [String] name given to form, passed to backend to identify form
    # @param [String] url for request
    # @param [Hash] options (see ActionView::Helpers::FormTagHelper.form_tag)
    def initialize(name:, url:, model: nil, **options)
      @name = name
      @url = url
      @options = options
      @model = model
      # if method is not passed in, we should make an assuption based on whether or not its a new record
    end

    def new_record?
      if @model.is_a? Valkyrie::ChangeSet
        @model.resource.new_record
      end
    end
  end
end
