# frozen_string_literal: true

# add a count to BulkExport
class AddCountToBulkExport < ActiveRecord::Migration[7.0]
  def change
    add_column :bulk_exports, :records_count, :integer
  end
end
