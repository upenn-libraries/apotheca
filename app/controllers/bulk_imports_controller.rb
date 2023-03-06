# frozen_string_literal: true

# controller actions for BulkImport
class BulkImportsController < ApplicationController
  load_and_authorize_resource

  include PerPage

  def index
    @bulk_imports = BulkImport.order(created_at: :desc)
                              .page(params[:page]).per(per_page)
                              .includes(:imports, :created_by)
  end
end
