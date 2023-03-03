# frozen_string_literal: true

module PerPage
  extend ActiveSupport::Concern

  included do
    before_action only: :index do
      session[:"#{controller_name}_per_page"] = params[:per_page] unless params[:per_page].nil?
    end
  end
end