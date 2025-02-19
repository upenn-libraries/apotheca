# frozen_string_literal: true

require_relative 'transaction_job'

describe GenerateAllDerivativesJob do
  let(:item) { persist(:item_resource, :with_full_assets_all_arranged, :published) }

  it_behaves_like 'TransactionJob' do
    let(:args) { [item.id.to_s, item.updated_by] }
  end
end
