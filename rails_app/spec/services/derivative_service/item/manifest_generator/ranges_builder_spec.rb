# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::RangesBuilder do
  describe '#build' do
    let(:asset) { persist(:asset_resource, :with_metadata) }
    let(:ranges) { described_class.new(asset).build }
    let(:canvas) { ranges.first.items.first }

    it 'builds ranges' do
      expect(ranges).to be_an Array
      expect(ranges.first).to be_a IIIF::V3::Presentation::Range
    end

    it 'assigns top-level attributes' do
      expect(ranges.first).to have_attributes(
        'id' => ending_with('toc/1'),
        'label' => { 'none' => ['Front of Card, Front'] },
        'items' => all(be_a(IIIF::V3::Presentation::Canvas))
      )
    end

    it 'assigns canvas attributes' do
      expect(canvas).to have_attributes(
        'id' => ending_with('canvas'),
        'label' => { 'none' => ['Front'] }
      )
    end
  end
end
