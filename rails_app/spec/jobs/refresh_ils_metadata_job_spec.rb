# frozen_string_literal: true

require_relative 'transaction_job'

describe RefreshIlsMetadataJob do
  let(:item) { persist(:item_resource) }

  it_behaves_like 'TransactionJob' do
    let(:args) { [item.id.to_s] }
  end
end
