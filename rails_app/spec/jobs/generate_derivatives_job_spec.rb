# frozen_string_literal: true

require_relative 'transaction_job'

describe GenerateDerivativesJob do
  let(:asset) { persist(:asset_resource, :with_preservation_file) }

  it_behaves_like 'TransactionJob' do
    let(:args) { [asset.id.to_s, asset.updated_by] }
  end
end
