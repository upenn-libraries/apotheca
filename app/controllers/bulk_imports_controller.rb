# frozen_string_literal: true

# controller actions for BulkImport
class BulkImportsController < ApplicationController
  load_and_authorize_resource

  include PerPage

  def index
    @users = User.with_imports
    @bulk_imports = BulkImport.order(created_at: :desc)
                              .page(params[:page]).per(per_page)
                              .includes(:imports, :created_by)

    @bulk_imports = @bulk_imports.filter_created_by(params.dig('filter', 'created_by')) if params.dig('filter', 'created_by').present?
    @bulk_imports = @bulk_imports.filter_created_between(params.dig('filter', 'start_date'), params.dig('filter', 'end_date')) if params.dig('filter', 'start_date').present? && params.dig('filter', 'end_date').present?
    @bulk_imports = @bulk_imports.search(params.dig('filter', 'search')) if params.dig('filter', 'search').present?
  end

  def show
    @state = params[:import_state]
    @imports = @bulk_import.imports.page(params[:import_page])
    @imports = @imports.where(state: @state).page(params[:import_page]) if @state
  end

  def csv
    send_data @bulk_import.csv, type: 'text/csv', filename: @bulk_import.original_filename, disposition: :download
  end

  def cancel
    @bulk_import.cancel_all(current_user)
    redirect_back_or_to bulk_import_path(@bulk_import), notice: 'All queued imports were cancelled'
  end

  def update; end
end
