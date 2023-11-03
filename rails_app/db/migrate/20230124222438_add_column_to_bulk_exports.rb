# rubocop:disable all
class AddColumnToBulkExports < ActiveRecord::Migration[7.0]
  def change
    add_column :bulk_exports, :title, :string
    add_column :bulk_exports, :generated_at, :datetime
    add_column :bulk_exports, :include_assets, :boolean, default: false
  end
end
