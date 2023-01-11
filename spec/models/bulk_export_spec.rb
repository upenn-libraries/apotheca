# frozen_string_literal: true

require_relative 'concerns/queueable'

describe BulkExport do
  it_behaves_like 'queueable'

  it "requires a user" do
    bulk_export = build :bulk_export, user: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['user']).to include "must exist"
  end

  it "requires solr params" do
    bulk_export = build :bulk_export, solr_params: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['solr_params']).to include "can't be blank"
  end

  it "requires state to be set" do
    bulk_export = build :bulk_export, state: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['state']).to include "can't be blank"
  end

end

