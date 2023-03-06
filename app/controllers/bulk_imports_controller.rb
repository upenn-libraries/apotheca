# frozen_string_literal: true

# controller actions for BulkImport
class BulkImportsController < ApplicationController
  load_and_authorize_resource
  def index
    @bulk_imports = BulkImport.order(created_at: :desc)
                              .page(params[:page])
                              .includes(:imports, :created_by)
  end

  def show
    @bulk_import = BulkImport.find(params[:id])
    @state = params[:import_state]
    @imports = @bulk_import.imports.page(params[:import_page])
    @imports = @imports.where(state: @state).page(params[:import_page]) if @state
  end

  def csv
    @bulk_import = BulkImport.find(params[:id])

    send_data @bulk_import.csv, type: 'text/csv', filename: @bulk_import.original_filename, disposition: :download
  end

end
