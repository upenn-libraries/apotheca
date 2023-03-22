# frozen_string_literal: true

describe ImportService::AssetsLocation do
  describe '#valid?' do
    it 'requires valid storage name' do
      location = described_class.new(storage: 'invalid')
      expect(location.valid?).to be false
      expect(location.errors).to include('assets storage invalid: \'invalid\'')
    end

    it 'requires at least one path' do
      location = described_class.new(storage: 'sceti_digitized', path: [])
      expect(location.valid?).to be false
      expect(location.errors).to include('assets must contain at least one path')
    end

    it 'requires valid paths' do
      location = described_class.new(storage: 'sceti_digitized', path: ['trade_card', 'not_valid'])
      expect(location.valid?).to be false
      expect(location.errors).to include('asset path invalid')
    end

    it 'requires unique filenames across all paths' do
      location = described_class.new(storage: 'sceti_digitized', path: ['trade_card', 'trade_card'])
      expect(location.valid?).to be false
      expect(location.errors).to include('duplicate filenames found in storage location: back.tif, front.tif')
    end
  end

  describe '#valid_paths?' do
    context 'when one path invalid' do
      let(:location) { described_class.new(storage: 'sceti_digitized', path: ['trade_card', 'not_valid']) }

      it 'returns false' do
        expect(location.valid_paths?).to be false
      end
    end
  end

  describe '#filenames' do
    let(:location) { described_class.new(storage: 'sceti_digitized', path: ['trade_card', 'bell.wav']) }

    it 'returns all filenames available at the paths given' do
      expect(location.filenames).to contain_exactly('front.tif', 'back.tif', 'bell.wav')
    end
  end

  describe '#file_for' do
    let(:location) { described_class.new(storage: 'sceti_digitized', path: ['trade_card']) }

    it 'raises error when file is not present' do
      expect {
        location.file_for('invalid_filename')
      }.to raise_error 'Could not find invalid_filename in storage'
    end

    it 'returns file when file is present' do
      expect(location.file_for('front.tif')).to be_a Tempfile
    end
  end
end
