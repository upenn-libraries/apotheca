# frozen_string_literal: true

module Form
  # Renders a form element. Has slots for fields, a submit button and an error message. If desired,
  # inputs can be grouped in sections.
  class Component < ViewComponent::Base
    renders_many :fields, lambda { |*field_path, **args, &block|
      Field::Component.new(*field_path, **@field_options.merge(args), &block)
    }

    renders_many :sections, lambda { |**options, &block|
      Section::Component.new(**@field_options, **options, &block)
    }

    renders_one :error, ErrorMessage::Component

    renders_one :submit, SubmitButton::Component

    # Generates form for the ActiveRecord, Valkyrie::ChangeSet or Valkyrie::Resource provided.
    # Currently, we only support a horizontal form layout though we could continue extending this component to support
    # alternative layouts.
    #
    # When a model is provided the form url and method can be automatically generated. Url and method
    # values provided will override the defaults. In cases where a model is provided field names
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
    # @param [String] url for request, optional
    # @param [ActiveRecord::Base|Valkyrie::ChangeSet|Valkyrie::Resource] model or change set that the form is representing, optional
    # @param [String, TrueClass, FalseClass] disable_with can be a String value for disabled version of submit button,
    # true for default value, or false to prevent disabling the submit button when the form is submitted
    # @param [Hash] options (see ActionView::Helpers::FormTagHelper.form_tag)
    # @option options [Symbol] :method to use for html form
    # @option options [Boolean] :multipart flag to be used when file upload present
    # @option options [Hash] :label_col bootstrap column to use for all labels
    # @option options [Hash] :input_col bootstrap column to use for all inputs
    # @option options [Symbol] :size to be used for labels and inputs
    # @option options [Boolean] :optimistic_lock override model inspection for placing of optimistic lock token
    def initialize(name: nil, url: nil, model: nil, disable_with: true, **options)
      @name = name
      @model = model
      @url = url
      @disable_with = disable_with
      @options = options
      configure_form_disable_with if disable_with

      # If method is not passed in, we set the appropriate method.
      @options[:method] = new_record? ? :post : :patch unless @options[:method]

      @field_options = {
        model: @model,
        size: @options.delete(:size),
        label_col: @options.delete(:label_col) || { sm: 2 },
        input_col: @options.delete(:input_col) || { sm: 10 }
      }
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
        @model.class.to_s.underscore.downcase
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

    # Should the locking token be rendered as a hidden field? This expects a value in @options[:optimistic_lock]
    # otherwise it checks the @model for #lockable? which is mixed in by the Lockability concerns
    # @return [TrueClass, FalseClass]
    def include_lock?
      return @options[:optimistic_lock] if @options[:optimistic_lock]&.in? [true, false]

      @model.try :lockable?
    end

    def configure_form_disable_with
      disable_with_value = @disable_with.is_a?(String) ? @disable_with : 'Processing...'
      @options[:data] ||= {}
      @options[:data].merge!(controller: 'form--form',
                             action: 'submit->form--form#disableSubmit',
                             'disable-with': disable_with_value)
    end
  end
end
