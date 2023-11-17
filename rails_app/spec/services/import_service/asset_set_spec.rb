# frozen_string_literal: true

describe ImportService::AssetSet do
  describe '#valid?' do
    it 'requires that asset storage valid' do
      assets = described_class.new(storage: 'invalid')
      expect(assets.valid?).to be false
      expect(assets.errors).to include "assets storage invalid: 'invalid'"
    end

    it 'requires that asset information is provided' do
      assets = described_class.new(arranged: {}, unarranged_filenames: '')
      expect(assets.valid?).to be false
      expect(assets.errors).to include 'no assets defined'
    end

    it 'requires that arranged filenames are not provided two different ways' do
      assets = described_class.new(arranged_filenames: 'a.tif', arranged: [{ filename: 'a.tif' }])
      expect(assets.valid?).to be false
      expect(assets.errors).to include(
        'arranged_filenames/unarranged_filenames cannot be used in conjunction with arranged/unarranged keys'
      )
    end

    it 'detects errors when both (arranged/unarranged) filenames and spreadsheet are used' do
      assets = described_class.new(arranged_filenames: 'a.tif', spreadsheet: [{ filename: 'a.tif' }])
      expect(assets.valid?).to be false
      expect(assets.errors).to include(
        '(arranged/unarranged)_filename or arranged/unarranged keys used alongside asset spreadsheet'
      )
    end

    it 'requires every row of asset spreadsheet has a filename' do
      assets = described_class.new(spreadsheet: [{ filename: 'a.tif' }, { label: 'no filename' }])
      expect(assets.valid?).to be false
      expect(assets.errors).to include('asset filename(s) missing')
    end

    it 'requires that paths are valid' do
      assets = described_class.new(storage: 'sceti_digitized', path: 'invalid/something')
      expect(assets.valid?).to be false
      expect(assets.errors).to include 'asset path invalid'
    end

    it 'requires that path is present when storage provided' do
      assets = described_class.new(storage: 'sceti_digitized', path: nil)
      expect(assets.valid?).to be false
      expect(assets.errors).to include 'assets must contain at least one path'
    end

    it 'requires that duplicate files are not present in any of the storage paths' do
      assets = described_class.new(storage: 'sceti_digitized', path: %w[trade_card/original trade_card/updated])
      expect(assets.valid?).to be false
      expect(assets.errors).to include 'duplicate filenames found in storage location: front.tif'
    end
  end
end
