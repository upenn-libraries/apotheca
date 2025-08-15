# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::RangesBuilder do
  describe '#build' do
    let(:asset) { persist(:asset_resource, :with_metadata) }
    let(:ranges) { described_class.new(asset).build }
    let(:range) { ranges.first }
    let(:canvas) { ranges.first.items.first }

    it 'builds ranges' do
      expect(ranges).to be_an Array
      expect(range).to be_a IIIF::V3::Presentation::Range
    end

    it 'assigns range ID' do
      expect(range.id).to start_with("https://#{Settings.app_url}")
        .and(ending_with('toc/1'))
    end

    it 'assigns range label' do
      expect(range.label).to eq(
        { 'none' => ['Front of Card, Front'] }
      )
    end

    it 'assigns range items' do
      expect(range.items).to be_an Array
      expect(canvas).to be_a IIIF::V3::Presentation::Canvas
    end

    it 'includes range items canvas id' do
      expect(canvas.id).to start_with("https://#{Settings.app_url}")
        .and(ending_with('canvas'))
    end

    it 'includes range items canvas label' do
      expect(canvas.label).to eq(
        { 'none' => ['Front'] }
      )
    end
  end
end
