# frozen_string_literal: true

class ChangeBulkExportSearchParamsDefaultValue < ActiveRecord::Migration[7.0]
  def change
    change_column_default :bulk_exports, :search_params, from: nil, to: {}
  end
end
