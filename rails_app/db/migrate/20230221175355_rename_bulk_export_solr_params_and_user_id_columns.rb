# rubocop:disable all
# frozen_string_literal: true

class RenameBulkExportSolrParamsAndUserIdColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :bulk_exports, :solr_params, :search_params
    rename_column :bulk_exports, :user_id, :created_by_id
  end
end
