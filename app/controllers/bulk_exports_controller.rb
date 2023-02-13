# frozen_string_literal: true

# controller actions for BulkExport
class BulkExportsController < ApplicationController
  load_and_authorize_resource
  def index
    authorize! :read, BulkExport
  end

  def new
    authorize! :new, BulkExport
    @bulk_export = BulkExport.new(solr_params: params[:solr_params])
  end

  def create
    authorize! :create, BulkExport
    @bulk_export = BulkExport.new(bulk_export_params)
    @bulk_export.user = current_user
    @bulk_export.solr_params = clean_params(JSON.parse(params[:bulk_export][:solr_params]))
    if @bulk_export.save
      ProcessBulkExportJob.perform_later(@bulk_export)
      redirect_to bulk_exports_path, notice: 'Bulk export created'
    else
      redirect_to bulk_exports_path, alert: "Problem creating bulk export: #{@bulk_export.errors.map(&:full_message).join(', ')}"
    end
  end

  private

  def bulk_export_params
    params.require(:bulk_export).permit(:title, :include_assets)
  end

  def clean_params(params)
    params.delete('rows')
    params['filter']['collection'] = params['filter']['collection'].reject(&:empty?)
    params['search']['fielded'] = params['search']['fielded'].reject{ |v| v['opr'].empty? && v['term'].empty? }
    params
  end
end
