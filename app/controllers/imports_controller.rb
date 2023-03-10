# frozen_string_literal: true

# controller actions for Import
class ImportsController < ApplicationController
  load_and_authorize_resource
  def show; end

  def cancel
    if @import.may_cancel? == false
      redirect_back_or_to bulk_import_import_path(@import.bulk_import, @import),
                  notice: 'Only queued imports may be cancelled'
    elsif @import.cancel!
      redirect_back_or_to bulk_import_import_path(@import.bulk_import, @import),
                          notice: "Import #{@import.id} cancelled"
    else
      redirect_back_or_to bulk_import_import_path(@import.bulk_import, @import),
                  notice: "An error occurred when cancelling the import: #{@import.process_errors.join(' ')}"
    end
  end
end
