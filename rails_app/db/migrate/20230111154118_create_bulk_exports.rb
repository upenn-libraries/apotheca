class CreateBulkExports < ActiveRecord::Migration[7.0]
  def change
    create_table :bulk_exports do |t|
      t.belongs_to :user, index: true
      t.jsonb :solr_params
      t.string :process_errors, array: true
      t.integer :duration
      t.string :state

      t.timestamps
    end
  end
end
