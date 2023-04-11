# frozen_string_literal: true

module ApplicationHelper
  # @param [String, Symbol] name
  # @return [String, nil]
  def bs_icon(name, **options)
    render Icon::Component.new name: name, **options
  end

  # @param [String] controller_name
  # @return [String] per_page
  def per_page_from_session(controller_name)
    session[:"#{controller_name}_per_page"] || params[:per_page]
  end

  # @return [UserPresenter]
  def current_user_presenter
    UserPresenter.new(object: current_user) if current_user.present?
  end

  # Override CanCanCan's #can? method to seamlessly handle presenter classes
  def can?(action, object)
    object = object.object if object.respond_to? :object

    super action, object
  end
end
