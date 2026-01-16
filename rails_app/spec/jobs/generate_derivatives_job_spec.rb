# frozen_string_literal: true

require_relative 'transaction_job'

describe GenerateDerivativesJob do
  let(:item) { persist(:item_resource, :with_full_asset, :with_bibnumber) }

  include_context 'with successful Alma request' do
    let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
  end

  it_behaves_like 'TransactionJob' do
    let(:args) { [item.asset_ids.first, item.updated_by] }
  end
end
