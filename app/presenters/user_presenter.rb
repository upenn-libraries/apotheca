# frozen_string_literal: true

# Presentation logic for a User
class UserPresenter < BasePresenter
  # @return [String (frozen)]
  def full_name
    "#{first_name} #{last_name}"
  end

  # @return [String (frozen)]
  def created_time
    created_at.to_fs(:display)
  end

  # @return [String (frozen)]
  def updated_time
    updated_at.to_fs(:display)
  end

  # @return [String (frozen)]
  def active_text
    active ? 'Yes' : 'No'
  end

  # @return [String (frozen)]
  def role_names
    roles.map(&:titleize).join(', ')
  end
end
