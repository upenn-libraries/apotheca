# frozen_string_literal: true

# controller actions for BulkExport
class BulkExportsController < ApplicationController
  load_and_authorize_resource
  def index
    authorize! :read, BulkExport
  end

  def new
    authorize! :new, BulkExport
    @bulk_export = BulkExport.new(solr_params: CGI.unescape(params[:query]))
  end

  def create
    authorize! :create, BulkExport
    @bulk_export = BulkExport.new(bulk_export_params)
    @bulk_export.user = current_user
    if @bulk_export.save
      ProcessBulkExportJob.perform_later(@bulk_export)
      redirect_to items_path, notice: 'Bulk export created'
    else
      render :new, alert: "Problem creating bulk export: #{@bulk_export.errors.map(&:full_message).join(', ')}"
    end
  end

  private

  def bulk_export_params
    params.require(:bulk_export).permit(:title, :solr_params, :include_assets)
  end
end
