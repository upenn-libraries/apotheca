# frozen_string_literal: true

require_relative 'transaction_job'

describe UpdateArkMetadataJob do
  let(:item) { persist(:item_resource, :with_bibnumber) }

  include_context 'with successful requests to update EZID'

  include_context 'with successful Alma request' do
    let(:xml) { File.read(file_fixture('alma/marc_xml/manuscript-1.xml')) }
  end

  it_behaves_like 'TransactionJob' do
    let(:args) { [item.id.to_s] }
  end
end
