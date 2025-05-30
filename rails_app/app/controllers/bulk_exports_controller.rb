# frozen_string_literal: true

# controller actions for BulkExport
class BulkExportsController < UIController
  include PerPage

  load_and_authorize_resource

  def index
    @users = User.with_exports
    @bulk_exports = BulkExport.with_created_by.page(params[:page]).per(per_page)
    if params.dig('filter', 'created_by').present?
      @bulk_exports = @bulk_exports.filter_created_by(params[:filter][:created_by])
    end
    @bulk_exports = @bulk_exports.sort_by_field(**sort_params.to_h.symbolize_keys)
  end

  def new
    @bulk_export = BulkExport.new(search_params: params[:search_params])
  end

  def create
    @bulk_export = BulkExport.new(bulk_export_params)
    @bulk_export.created_by = current_user
    @bulk_export.search_params = clean_search_params(JSON.parse(params[:bulk_export][:search_params]))
    if @bulk_export.save
      ProcessBulkExportJob.perform_async(@bulk_export.id)
      redirect_to bulk_exports_path, notice: 'Bulk export created'
    else
      redirect_to bulk_exports_path,
                  alert: "Problem creating bulk export: #{@bulk_export.errors.map(&:full_message).join(', ')}"
    end
  end

  def destroy
    if @bulk_export.processing? || @bulk_export.queued?
      redirect_to bulk_exports_path, alert: "Cannot delete a bulk export that is #{@bulk_export.state}."
    elsif @bulk_export.destroy
      redirect_to bulk_exports_path, notice: 'Bulk export deleted.'
    else
      redirect_to bulk_exports_path,
                  alert: "An error occurred while deleting the bulk export: #{@bulk_export.errors.full_messages.join(', ')}"
    end
  end

  def cancel
    if !@bulk_export.may_cancel?
      redirect_to bulk_exports_path, alert: 'Cannot cancel a bulk export that is processing.'
    elsif @bulk_export.cancel!
      redirect_to bulk_exports_path, notice: 'Bulk export cancelled.'
    else
      redirect_to bulk_export_path,
                  alert: "An error occurred while cancelling the bulk export: #{@bulk_export.errors.full_messages.join(', ')}"
    end
  end

  def regenerate
    if !@bulk_export.may_reprocess?
      redirect_to bulk_exports_path, notice: "Can't regenerate bulk export that is #{@bulk_export.state}"
    elsif @bulk_export.reprocess!
      ProcessBulkExportJob.perform_async(@bulk_export.id)
      redirect_to bulk_exports_path, notice: 'Bulk export queued for regeneration.'
    else
      redirect_to bulk_export_path,
                  alert: "An error occurred while regenerating the bulk export: #{@bulk_export.errors.full_messages.join(', ')}"
    end
  end

  private

  def bulk_export_params
    params.require(:bulk_export).permit(:title, :include_assets).compact_blank!
  end

  def clean_search_params(search_params)
    return {} if search_params.blank?

    if search_params.dig('search', 'fielded')
      search_params['search']['fielded'] = search_params['search']['fielded'].reject { |v| v['term'].blank? }
    end
    search_params
  end

  def sort_params
    params.fetch(:sort, {}).permit(:field, :direction).compact_blank!
  end
end
