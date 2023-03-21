# frozen_string_literal: true

# controller actions for BulkImport
class BulkImportsController < ApplicationController
  load_and_authorize_resource except: [:create]

  include PerPage

  def index
    @bulk_imports = BulkImport.order(created_at: :desc)
                              .page(params[:page]).per(per_page)
                              .includes(:imports, :created_by)
  end

  def new; end

  def create
    authorize! :create, BulkImport
    @bulk_import = BulkImport.new(created_by: current_user, note: params[:bulk_import][:note])
    uploaded_file = params[:bulk_import][:csv]
    uploaded_file.tempfile.set_encoding('UTF-8')
    @bulk_import.original_filename = uploaded_file.original_filename
    csv = uploaded_file.read

    if @bulk_import.save
      @bulk_import.create_imports(csv, safe_queue_name_from(params[:bulk_import][:job_priority].to_s))
      redirect_to bulk_imports_path, notice: 'Bulk import created'
    else
      redirect_to bulk_imports_path, alert: "Problem creating bulk import: #{@bulk_import.errors.map(&:full_message).join(', ')}"
    end
  end

  def show
    @state = params[:import_state]
    @imports = @bulk_import.imports.page(params[:import_page])
    @imports = @imports.where(state: @state).page(params[:import_page]) if @state
  end

  def csv
    send_data @bulk_import.csv, type: 'text/csv', filename: @bulk_import.original_filename, disposition: :download
  end

  private

  # @param [String] priority_param
  # @return [String]
  def safe_queue_name_from(priority_param)
    if priority_param.in?(BulkImport::PRIORITY_QUEUES)
      priority_param
    else
      BulkImport::DEFAULT_PRIORITY
    end
  end
end
