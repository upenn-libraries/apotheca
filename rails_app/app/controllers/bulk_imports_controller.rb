# frozen_string_literal: true

# controller actions for BulkImport
class BulkImportsController < ApplicationController
  load_and_authorize_resource
  # We have to skip auto-loading for the create action because
  # load_and_authorize_resource expects strong parameters
  skip_load_resource only: :create

  include PerPage

  def index
    @users = User.with_imports
    @bulk_imports = BulkImport.order(created_at: :desc)
                              .page(params[:page]).per(per_page)
                              .includes(:imports, :created_by)

    if params.dig('filter', 'created_by').present?
      @bulk_imports = @bulk_imports.filter_created_by(params.dig('filter', 'created_by'))
    end

    if params.dig('filter', 'start_date').present? || params.dig('filter', 'end_date').present?
      @bulk_imports = @bulk_imports.filter_created_between(
        params.dig('filter', 'start_date'), params.dig('filter', 'end_date')
      )
    end

    @bulk_imports = @bulk_imports.search(params.dig('filter', 'search')) if params.dig('filter', 'search').present?
  end

  def show
    @state = params[:import_state]
    @imports = @bulk_import.imports.page(params[:import_page])
    @imports = @imports.where(state: @state).page(params[:import_page]) if @state
  end

  def new; end

  def create
    @bulk_import = BulkImport.new(created_by: current_user, note: params[:bulk_import][:note])
    uploaded_file = params[:bulk_import][:csv]
    uploaded_file.tempfile.set_encoding('UTF-8')
    @bulk_import.original_filename = uploaded_file.original_filename

    csv = uploaded_file.read
    begin
      @bulk_import.csv_rows = StructuredCSV.parse(csv)
    rescue CSV::MalformedCSVError => e
      return redirect_to bulk_imports_path, alert: "Problem creating bulk import: #{e.message}"
    end

    if @bulk_import.empty_csv?
      return redirect_to bulk_imports_path, alert: 'Problem creating bulk import: CSV has no item data'
    end

    if @bulk_import.save
      @bulk_import.create_imports(safe_queue_name_from(params[:bulk_import][:job_priority].to_s))
      redirect_to bulk_import_path(@bulk_import), notice: 'Bulk import created'
    else
      redirect_to bulk_imports_path,
                  alert: "Problem creating bulk import: #{@bulk_import.errors.map(&:full_message).join(', ')}"
    end
  end

  def cancel
    @bulk_import.cancel_all(current_user)
    redirect_back_or_to bulk_import_path(@bulk_import), notice: 'All queued imports were cancelled'
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

  # @return [Array<ActionDispatch::Http::UploadedFile>]
  def structural_metadata_files
    params[:structural_metadata] || []
  end

  # @return [Array<String>]
  def structural_metadata_filenames
    @structural_metadata_filenames ||= structural_metadata_files.map(&:original_filename)
  end

  # @return [Hash]
  def structural_metadata_hash
    hash = {}

    return hash if structural_metadata_files.empty?

    structural_metadata_files.each do |file|
      csv = file.read
      hash[file.original_filename] = StructuredCSV.parse(csv)
    end
    hash
  end

  # @param [Array<Hash>] rows
  # @return [Boolean]
  def missing_metadata_file?(rows)
    filenames_from_bulk_import_csv = rows.map do |row|
      row['assets']['spreadsheet_filename']
    end
    filenames_from_bulk_import_csv.sort != structural_metadata_filenames.sort
  end
end
