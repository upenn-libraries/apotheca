# frozen_string_literal: true

describe GenerateIIIFManifests do
  describe '#call' do
    subject(:updated_item) { result.value! }

    let(:transaction) { described_class.new }
    let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }
    let(:result) { transaction.call(id: item.id.to_s, updated_by: 'initiator@example.com') }

    context 'when item is not published' do
      it 'adds IIIF manifests derivatives' do
        expect(updated_item.derivatives.length).to be 2
        expect(updated_item.derivatives.map(&:type)).to contain_exactly('iiif_manifest', 'iiif_v3_manifest')
      end
    end

    context 'when item is published' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives) }

      it 'has expected derivatives' do
        expect(updated_item.derivatives.length).to be 3
        expect(updated_item.derivatives.map(&:type)).to contain_exactly('pdf', 'iiif_manifest', 'iiif_v3_manifest')
      end

      it 'generated IIIF manifest after PDF was generated' do
        # Creating item first and then sleeping to ensure a time difference.
        item
        sleep 2.0

        expect(updated_item.iiif_manifest.generated_at).to be > updated_item.pdf.generated_at
        expect(updated_item.iiif_v3_manifest.generated_at).to be > updated_item.pdf.generated_at
      end
    end
  end
end
