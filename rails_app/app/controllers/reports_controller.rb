# frozen_string_literal: true

# controller actions for Report
class ReportsController < UIController
  include PerPage

  load_and_authorize_resource

  def index
    @reports = Report.order(updated_at: :desc).page(params[:page]).per(per_page)
  end
end
