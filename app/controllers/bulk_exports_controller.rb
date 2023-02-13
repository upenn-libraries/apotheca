# frozen_string_literal: true

# controller actions for BulkExport
class BulkExportsController < ApplicationController
  load_and_authorize_resource
  def index
    @users = User.user_with_exports
    @bulk_exports = BulkExport.with_user.page(params[:page])
    @bulk_exports = @bulk_exports.filter_user(params[:filter][:user]) if params.dig('filter', 'user').present?
    @bulk_exports = @bulk_exports.sort_by_field(params[:sort][:field], params[:sort][:direction]) if params[:sort].present?
  end
end
