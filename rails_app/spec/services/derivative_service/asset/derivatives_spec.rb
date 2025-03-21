# frozen_string_literal: true

describe DerivativeService::Asset::Derivatives do
  describe '#new' do
    context 'when asset is not a AssetChangeSet' do
      let(:asset) { ItemChangeSet.new(ItemResource.new) }

      it 'raises error' do
        expect { described_class.new(asset) }.to raise_error(ArgumentError, 'Asset provided must be an AssetChangeSet')
      end
    end

    context 'when mime_type is not available' do
      let(:asset) { AssetChangeSet.new(AssetResource.new) }

      it 'raises error' do
        expect { described_class.new(asset) }.to raise_error('Missing mime type')
      end
    end
  end

  describe '#generator' do
    let(:file) { Tempfile.new }
    let(:derivatives) { described_class.new(asset) }

    context 'when mime_type not supported' do
      let(:asset) { AssetChangeSet.new(persist(:asset_resource, :with_pdf_file)) }

      it 'returns Generator::Default' do
        expect(derivatives.generator).to be_a DerivativeService::Asset::Generator::Default
      end
    end

    context 'when mime_type is supported by image generator' do
      let(:asset) { AssetChangeSet.new(persist(:asset_resource, :with_image_file)) }

      it 'returns Generator::Image' do
        expect(derivatives.generator).to be_a DerivativeService::Asset::Generator::Image
      end
    end
  end

  describe '.generate_for?' do
    it 'returns true when supported mime type' do
      expect(described_class.generate_for?('image/tiff')).to be true
    end

    it 'returns false when unsupported mime type' do
      expect(described_class.generate_for?('application/pdf')).to be false
    end
  end
end
