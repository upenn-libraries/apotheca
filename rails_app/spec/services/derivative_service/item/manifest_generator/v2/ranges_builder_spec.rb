# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::V2::RangesBuilder do
  describe '#build' do
    subject(:ranges) { described_class.new(asset: asset).build }

    context 'when asset contains annotations' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives, :with_metadata) }

      it 'builds an array of range' do
        expect(ranges[0]).to be_a IIIF::Presentation::Range
      end

      it 'assigns id' do
        expect(ranges[0]['@id']).to match(%r{/iiif/2/assets/.+/toc/1$})
      end

      it 'includes annotation and appends label' do
        expect(ranges[0]['label']).to eql 'Front of Card, Front'
      end

      it 'assigns canvas that its referencing' do
        expect(ranges[0]['canvases']).to contain_exactly(match(%r{/iiif/2/assets/.+/canvas$}))
      end
    end

    context 'when annotation contains label' do
      let(:asset) do
        persist(:asset_resource, :with_image_file, :with_derivatives,
                label: '1r', annotations: [{ text: 'multiplication chart, 1r' }])
      end

      it 'does not append label' do
        expect(ranges[0]['label']).to eql 'multiplication chart, 1r'
      end
    end

    context 'when asset contains multiple annotations' do
      let(:asset) do
        persist(:asset_resource, :with_image_file, :with_derivatives,
                label: '1r', annotations: [{ text: 'multiplication chart, 1r' }, { text: 'illustration' }])
      end

      it 'returns two ranges' do
        expect(ranges.length).to eq 2
      end
    end

    context 'when asset does not contain annotations' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }

      it 'return empty array' do
        expect(ranges).to eql []
      end
    end
  end
end
