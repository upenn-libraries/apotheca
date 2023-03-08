# frozen_string_literal: true

# controller actions for BulkImport
class BulkImportsController < ApplicationController
  load_and_authorize_resource
  def index
    @users = User.with_imports
    @bulk_imports = BulkImport.order(created_at: :desc)
                              .page(params[:page])
                              .includes(:imports, :created_by)
    @bulk_imports = @bulk_imports.filter_created_by(params[:filter][:created_by]) if params.dig('filter', 'created_by').present?
  end

  def show
    @state = params[:import_state]
    @imports = @bulk_import.imports.page(params[:import_page])
    @imports = @imports.where(state: @state).page(params[:import_page]) if @state
  end

  def csv
    send_data @bulk_import.csv, type: 'text/csv', filename: @bulk_import.original_filename, disposition: :download
  end

end
