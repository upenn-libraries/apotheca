# frozen_string_literal: true

# Presentation logic for a User
class UserPresenter < BasePresenter
  # @return [String (frozen)]
  def full_name
    "#{first_name} #{last_name}"
  end
end
