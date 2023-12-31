# frozen_string_literal: true

# Application-wide helper methods
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
  def can?(action, subject, attribute = nil, *extra_args)
    subject = subject.object if subject.respond_to? :object

    super action, subject, attribute, *extra_args
  end
end
