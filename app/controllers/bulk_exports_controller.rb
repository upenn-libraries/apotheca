# frozen_string_literal: true

# controller actions for BulkExport
class BulkExportsController < ApplicationController
  load_and_authorize_resource

  def index
    @users = User.with_exports
    @bulk_exports = BulkExport.with_user.page(params[:page])
    @bulk_exports = @bulk_exports.filter_user(params[:filter][:user]) if params.dig('filter', 'user').present?
    @bulk_exports = @bulk_exports.sort_by_field(params[:sort][:field], params[:sort][:direction]) if params[:sort].present?
  end

  def new
    @bulk_export = BulkExport.new(solr_params: params[:solr_params])
  end

  def create
    @bulk_export = BulkExport.new(bulk_export_params)
    @bulk_export.user = current_user
    @bulk_export.solr_params = clean_search_params(JSON.parse(params[:bulk_export][:solr_params]))
    if @bulk_export.save
      ProcessBulkExportJob.perform_later(@bulk_export)
      redirect_to bulk_exports_path, notice: 'Bulk export created'
    else
      redirect_to bulk_exports_path, alert: "Problem creating bulk export: #{@bulk_export.errors.map(&:full_message).join(', ')}"
    end
  end

  def destroy
    if @bulk_export.processing?
      redirect_to bulk_exports_path, alert: 'Cannot delete a bulk export that is currently processing.'
    else
      if @bulk_export.destroy
        redirect_to bulk_exports_path, notice: 'Bulk export deleted.'
      else
        redirect_to bulk_exports_path, alert: "An error occurred while deleting the bulk export: #{@bulk_export.errors.map(&:full_message).join(', ')}"
      end
    end
  end

  def cancel
    if @bulk_export.may_cancel?
      if @bulk_export.cancel!
        redirect_to bulk_exports_path, notice: 'Bulk export cancelled.'
      else
        redirect_to bulk_export_path, alert: "Bulk export cancellation failed: #{@bulk_export.errors.map(&:full_message).join(', ')}"
      end
    else
      redirect_to bulk_exports_path, alert: 'Cannot cancel a bulk export that is processing.'
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
