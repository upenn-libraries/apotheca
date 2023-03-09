# frozen_string_literal: true

module ApplicationHelper
  # @param [String, Symbol] name
  # @return [String, nil]
  def bs_icon(name, **options)
    render Icon::Component.new name: name, **options
  end

  # @return [UserPresenter]
  def current_user_presenter
    UserPresenter.new(object: current_user) if current_user.present?
  end
end
