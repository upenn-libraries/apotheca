# frozen_string_literal: true

# Render a button that will toggle a single-valued attribute on resource
class AttributeToggleComponent < ViewComponent::Base
  attr_accessor :attribute, :value, :resource, :do_label, :done_label

  def initialize(resource:, attribute:, value:, do_label:, done_label:)
    @resource = resource
    @attribute = attribute
    @value = value
    @do_label = do_label
    @done_label = done_label
  end

  def entity
    resource.class.name.sub('Resource', '').downcase.pluralize
  end

  def toggled?
    @toggled ||= (resource.public_send(attribute) == value)
  end

  def classes
    toggled? ? 'btn btn-secondary' : 'btn btn-primary'
  end

  def disabled?
    toggled?
  end

  def label
    toggled? ? done_label : do_label
  end

  # @return [ActiveSupport::SafeBuffer]
  def call
    button_to label,
              { controller: entity, action: :update, id: resource.id },
              method: :patch,
              data: { stimulis_whatev: 'toggle' },
              disabled: disabled?,
              params: { "#{entity}[#{attribute}]" => value },
              class: ['mt-3'] << classes
  end
end
