# frozen_string_literal: true

describe DeleteAsset do
  let(:transaction) { described_class.new }
  let(:asset) { persist(:asset_resource) }

  describe '#call' do
    let(:result) { transaction.call(id: asset.id) }

    it 'is successful' do
      expect(result.success?).to be true
    end

    it 'deletes asset' do
      query_service = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service
      expect {
        query_service.find_by(id: result.value!.id)
      }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
    end
  end
end
