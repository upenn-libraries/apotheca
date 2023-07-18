# frozen_string_literal: true

module Form
  module Section
    # Component to define a section of a form.
    class Component < ViewComponent::Base
      renders_one :title, ->(**args, &block) { BaseComponent.new(:h4, **args, &block) }

      renders_many :fields, lambda { |*field_path, **args, &block|
        Field::Component.new(*field_path, **@field_options.merge(args), &block)
      }

      def initialize(**options)
        @options = options

        # Extracting options that should be passed to the field component.
        @field_options = @options.extract!(:model, :label_col, :input_col, :size)
      end
    end
  end
end
