# rubocop:disable all
class AddNotNullConstraintToOriginalFilename < ActiveRecord::Migration[7.0]
  def change
    change_column_null :bulk_imports, :original_filename, false
  end
end
