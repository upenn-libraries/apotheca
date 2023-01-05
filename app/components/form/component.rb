# frozen_string_literal: true

module Form
  # Renders a form element. Has slots for fields, a submit button and an error message. If desired,
  # inputs can be grouped in sections.
  class Component < ViewComponent::Base
    renders_many :fields, ->(*field_path, **args, &block) {
      Field::Component.new(*field_path, model: @model, **args, &block)
    }

    renders_many :sections, ->(**options, &block) {
      Section::Component.new(model: @model, **options, &block)
    }

    renders_one :error, ErrorMessage::Component

    renders_one :submit, SubmitButton::Component

    # Requires name and url. If a model is provided the form method can be assumed and field names
    # and values don't have to be explicitly provided. Any additional arguments will be passed
    # to the form_tag helper.
    #
    # A `:method` parameter should be provided if the action is something other than creating
    # or updating a record. If the form contains file inputs a truthy `:multipart` parameter
    #  should be provided.
    #
    # @param [String] name given to form, passed to backend to identify form
    # @param [String] url for request
    # @param [Valkyrie::ChangeSet] model or change set that the form is representing
    # @param [Hash] options (see ActionView::Helpers::FormTagHelper.form_tag)
    def initialize(name:, url:, model: nil, **options)
      @name = name
      @url = url
      @model = model
      @options = options

      # If method is not passed in, we set the appropriate method.
      @options[:method] = new_record? ? :post : :patch unless @options[:method]
    end

    def new_record?
      raise ArgumentError, 'model must be provided to form to automatically generate url or method' unless @model

      if @model.is_a? Valkyrie::ChangeSet
        @model.resource.new_record
      end
    end
  end
end
