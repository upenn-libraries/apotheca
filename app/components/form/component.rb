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

    # Generates form for the ActiveRecord, Valkyrie::ChangeSet or Valkyrie::Resource provided.
    #
    # When a model is provided the form url and method can be automatically generated. Url and method
    # values provided will override the defaults. Also in cases where a model is provided field names
    # and values don't have to be explicitly provided. When a model is NOT provided a method and
    # url must be provided.
    #
    # Generally, a `:method` parameter should be provided if the action is something other than creating
    # or updating a record. If the form contains file inputs a truthy `:multipart` parameter should be provided.
    #
    # A `name` parameter should be provided when there are multiple form on the same page.
    #
    # Any additional arguments will be passed to the form_tag helper.
    #
    # @param [String] name given to form, passed to backend to identify form
    # @param [String] url for request
    # @param [Valkyrie::ChangeSet] model or change set that the form is representing
    # @param [Hash] options (see ActionView::Helpers::FormTagHelper.form_tag)
    def initialize(name: nil, url: nil, model: nil, **options)
      @name = name
      @model = model
      @url = url
      @options = options

      # If method is not passed in, we set the appropriate method.
      @options[:method] = new_record? ? :post : :patch unless @options[:method]
    end

    def url
      @url || generate_url
    end

    def generate_url
      new_record? ? send("#{model_name.pluralize}_path") : send("#{model_name}_path", @model)
    end

    def model_name
      case @model
      when Valkyrie::ChangeSet
        @model.class.to_s.underscore.delete_suffix('_change_set')
      when Valkyrie::Resource
        @model.class.to_s.underscore.delete_suffix('_resource')
      else
        @model.model_name.param_key
      end
    end

    def new_record?
      raise ArgumentError, 'model must be provided to form to automatically generate method' unless @model

      case @model
      when Valkyrie::ChangeSet
        @model.resource.new_record
      when Valkyrie::Resource
        @model.new_record
      else
        @model.new_record?
      end
    end
  end
end
