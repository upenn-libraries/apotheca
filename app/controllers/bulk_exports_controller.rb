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

  def destroy
    @bulk_export = BulkExport.find(params[:id])
    if @bulk_export.processing?
      redirect_to bulk_exports_path, alert: 'Cannot delete a bulk export that is currently processing.'
    else
      @bulk_export.destroy
      redirect_to bulk_exports_path, notice: 'Bulk export deleted.'
    end
  end
end
