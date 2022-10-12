module Form
  module SubmitButton
    class Component < ViewComponent::Base
      def initialize(value, variant: :primary)
        @value = value
        @variant = variant
      end

      def call
        submit_tag @value, class: classes
      end

      private

      def classes
        ['btn', "btn-#{@variant}"]
      end
    end
  end

end