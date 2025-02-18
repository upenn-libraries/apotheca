# frozen_string_literal: true

class RenameStatusToStateInReports < ActiveRecord::Migration[7.1]
  def change
    rename_column :reports, :status, :state
  end
end
