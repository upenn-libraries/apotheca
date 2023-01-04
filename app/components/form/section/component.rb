# frozen_string_literal: true

module Form
  module Section
    # Component to define a section of a form.
    class Component < ViewComponent::Base
      renders_one :title, ->(**options, &block) { BaseComponent.new(:h4, **options, &block) }

      renders_many :fields, ->(*field_path, **args, &block) {
        Field::Component.new(*field_path, model: @model, **args, &block)
      }

      def initialize(model: nil, **options)
        @model = model
        @options = options
      end
    end
  end
end
