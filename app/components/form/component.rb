# frozen_string_literal: true

# Renders a form element that .... performs form submission via turbo and displays errors inline without re-rendering.
# going forward, we should be using this form element for all of our forms....
module Form
  class Component < ViewComponent::Base
    renders_many :inputs, types: {
      text: lambda { |**system_arguments| Input::Component.new(type: :text, **system_arguments) },
      select: lambda { |**system_arguments| Input::Component.new(type: :select, **system_arguments) }
    }

    renders_one :submit, SubmitButton::Component

    def initialize(url:, method:)
      @url = url
      @method = method
    end
  end
end