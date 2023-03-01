# frozen_string_literal: true

# controller actions for BulkImport
class BulkImportsController < ApplicationController
  def index
    @bulk_imports = BulkImport.order(created_at: :desc)
                              .page(params[:page])
                              .includes(:imports, :created_by)
  end

  def show
    @bulk_import = BulkImport.find(params[:id])
  end
end
