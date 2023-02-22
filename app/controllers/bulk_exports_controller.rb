# frozen_string_literal: true

# controller actions for BulkExport
class BulkExportsController < ApplicationController
  load_and_authorize_resource

  def index
    @users = User.with_exports
    @bulk_exports = BulkExport.with_created_by.page(params[:page])
    @bulk_exports = @bulk_exports.filter_created_by(params[:filter][:created_by]) if params.dig('filter', 'created_by').present?
    @bulk_exports = @bulk_exports.sort_by_field(params[:sort][:field], params[:sort][:direction]) if params[:sort].present?
  end

  def new
    @bulk_export = BulkExport.new(search_params: params[:search_params])
  end

  def create
    @bulk_export = BulkExport.new(bulk_export_params)
    @bulk_export.created_by = current_user
    @bulk_export.search_params = clean_search_params(JSON.parse(params[:bulk_export][:search_params]))
    if @bulk_export.save
      ProcessBulkExportJob.perform_later(@bulk_export)
      redirect_to bulk_exports_path, notice: 'Bulk export created'
    else
      redirect_to bulk_exports_path, alert: "Problem creating bulk export: #{@bulk_export.errors.map(&:full_message).join(', ')}"
    end
  end

  private

  def bulk_export_params
    params.require(:bulk_export).permit(:title, :include_assets).compact_blank!
  end

  def clean_search_params(search_params)
    search_params.delete('rows')
    search_params['filter']['collection'] = search_params['filter']['collection'].reject(&:empty?)
    search_params['search']['fielded'] = search_params['search']['fielded'].reject{ |v| v['term'].blank? }
    search_params
  end
end
