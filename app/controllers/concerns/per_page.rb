# frozen_string_literal: true

module PerPage
  extend ActiveSupport::Concern

  PER_PAGE_OPTIONS = [10, 25, 50, 100].freeze

  included do
    before_action only: :index do
      session[:"#{controller_name}_per_page"] = params[:per_page] unless params[:per_page].nil?
    end
  end

  def per_page
    params[:per_page] || session[:"#{controller_name}_per_page"]
  end
end
