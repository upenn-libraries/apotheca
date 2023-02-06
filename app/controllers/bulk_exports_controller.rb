# frozen_string_literal: true

# controller actions for BulkExport
class BulkExportsController < ApplicationController
  load_and_authorize_resource
  def index; end

  def new
    # instantiate new bulk export
    authorize! :new, BulkExport
    @bulk_export = BulkExport.new(solr_params: { test: 'params' }.to_json)
  end

  def create
    # create and save bulk export
  end
end
