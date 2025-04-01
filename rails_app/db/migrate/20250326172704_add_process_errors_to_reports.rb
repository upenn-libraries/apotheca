# frozen_string_literal: true

class AddProcessErrorsToReports < ActiveRecord::Migration[7.1]
  def change
    add_column :reports, :process_errors, :string, array: true
  end
end
