class MultivaluedInputComponent < ViewComponent::Base
  # TODO: Make this class more general so that it can also be used with single valued fields, we may
  #       need to rename this component.
  def initialize(label:, value:, field:)
    @label = label.to_s.titlecase
    @id = label.to_s.downcase.gsub(' ', '-')
    @value = value[0] # this value should be an array, for now, will convert to single value
    @field = field
  end
end