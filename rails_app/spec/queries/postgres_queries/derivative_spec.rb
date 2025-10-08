# frozen_string_literal: true

describe PostgresQueries::Derivative do
  let(:query) do
    described_class.new(query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service)
  end

  describe '#items_without_derivative' do
    let!(:items_without_derivatives) { [persist(:item_resource), persist(:item_resource)].map(&:id) }

    before { persist(:item_resource, :with_full_assets_all_arranged, :with_derivatives) }

    context 'when querying for items without iiif_manifests' do
      it 'returns only items without iiif manifests' do
        expect(query.items_without_derivative(type: :iiif_manifest).map(&:id)).to match_array(items_without_derivatives)
      end
    end

    context 'when querying for items without pdfs' do
      it 'returns only items without pdfs' do
        expect(query.items_without_derivative(type: :pdf).map(&:id)).to match_array(items_without_derivatives)
      end
    end
  end
end
