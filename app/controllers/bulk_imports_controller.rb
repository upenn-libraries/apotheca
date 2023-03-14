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

  def new; end

  def show
    @state = params[:import_state]
    @imports = @bulk_import.imports.page(params[:import_page])
    @imports = @imports.where(state: @state).page(params[:import_page]) if @state
  end

  def csv
    send_data @bulk_import.csv, type: 'text/csv', filename: @bulk_import.original_filename, disposition: :download
  end

  def bulk_import_params
    params.require(:bulk_import).permit(:original_filename, :csv, :note)
  end

end
