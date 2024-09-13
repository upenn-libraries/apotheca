# frozen_string_literal: true

describe ImportService::MigrationAssetSet do
  describe '#valid?' do
    it 'requires that asset storage valid' do
      asset_set = described_class.new(storage: 'invalid')
      expect(asset_set.valid?).to be false
      expect(asset_set.errors).to include "assets storage invalid: 'invalid'"
    end

    it 'requires that asset information is provided' do
      asset_set = described_class.new(arranged: [], unarranged: [])
      expect(asset_set.valid?).to be false
      expect(asset_set.errors).to include 'no assets defined'
    end

    it 'requires that paths are valid' do
      asset_set = described_class.new(
        storage: 'ceph_test', bucket: 'sceti-digitized-test',
        arranged: [{ filename: 'front.tif', path: 'invalid/something', checksum: '123' }]
      )
      expect(asset_set.valid?).to be false
      expect(asset_set.errors).to include 'path invalid for front.tif'
    end

    it 'requires unarranged asset to have path' do
      asset_set = described_class.new(unarranged: [{ filename: 'front.tif', checksum: '123' }])
      expect(asset_set.valid?).to be false
      expect(asset_set.errors).to include 'unarranged assets missing data'
    end

    it 'requires arranged asset to have path' do
      asset_set = described_class.new(arranged: [{ filename: 'front.tif', checksum: '123' }])
      expect(asset_set.valid?).to be false
      expect(asset_set.errors).to include 'arranged assets missing data'
    end

    it 'requires that skipped assets are present' do
      asset_set = described_class.new(
        ignored_assets: ['back.tif'], arranged: [{ filename: 'front.tif', checksum: '123' }]
      )
      expect(asset_set.valid?).to be false
      expect(asset_set.errors).to include 'cannot skip assets that are not present: back.tif'
    end
  end
end
