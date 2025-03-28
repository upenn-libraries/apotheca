# frozen_string_literal: true

module Popover
  # Popover component
  class Component < ViewComponent::Base
    attr_reader :title, :popover_content, :text, :link_style

    # Initializes the popover with the given attributes.
    # @param title [String] The title of the popover.
    # @param popover_content [String] The content of the popover.
    # @param text [String] The text that be used to trigger the popover.
    def initialize(title:, popover_content:, text:, link_style: 'primary')
      @title = title
      @popover_content = popover_content
      @text = text
      @link_style = link_style
    end
  end
end
