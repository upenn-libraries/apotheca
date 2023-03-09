# frozen_string_literal: true

module ApplicationHelper
  # @param [String, Symbol] name
  # @return [String, nil]
  def bs_icon(name, **options)
    render Icon::Component.new name: name, **options
  end

  # @param [BootstrapForm::FormBuilder] form
  # @return [String]
  def per_page_select(form)
    form.select 'per_page',
                options_for_select(PerPage::PER_PAGE_OPTIONS,
                                   session[:"#{controller_name}_per_page"] || params[:per_page]),
                label: 'Per Page'
  end

  # @return [UserPresenter]
  def current_user_presenter
    UserPresenter.new(object: current_user) if current_user.present?
  end
end
