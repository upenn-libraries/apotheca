module Form
  module Section
    # Component to define a section of a form.
    class Component < ViewComponent::Base
      renders_one :title, ->(&block) do
        content_tag :h4, &block
      end

      renders_many :inputs, types: {
        text: lambda { |**system_arguments| Input::Component.new(type: :text, **system_arguments) },
        select: lambda { |**system_arguments| Input::Component.new(type: :select, **system_arguments) }
      }
    end
  end
end