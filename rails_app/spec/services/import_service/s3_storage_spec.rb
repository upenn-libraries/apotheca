# frozen_string_literal: true

describe ImportService::S3Storage do
  let(:storage) { described_class.new('sceti_digitized') }

  describe '#file' do
    context 'when key is valid' do
      let(:file) { storage.file('trade_card/original/front.tif') }

      it 'returns ImportService::S3Storage::File' do
        expect(file).to be_a ImportService::S3Storage::File
        expect(file.original_filename).to eql 'front.tif'
      end
    end

    context 'when key is invalid' do
      it 'returns an error' do
        expect { storage.file('invalid') }.to raise_error(Shrine::FileNotFound)
      end
    end
  end

  describe '#valid_path?' do
    context 'when the path is valid' do
      it 'returns true' do
        expect(storage.valid_path?('trade_card/original')).to be true
      end
    end

    context 'when path is partial of valid path' do
      it 'returns false' do
        expect(storage.valid_path?('tra')).to be false
      end
    end

    context 'when the path is invalid' do
      it 'returns false' do
        expect(storage.valid_path?('invalid')).to be false
      end
    end

    context 'when the path contains only directories' do
      it 'returns true' do
        expect(storage.valid_path?('trade_card')).to be true
      end
    end

    context 'when the path is a filename' do
      it 'returns true' do
        expect(storage.valid_path?('trade_card/original/front.tif')).to be true
      end
    end
  end

  describe '#files_at' do
    context 'when path invalid' do
      it 'returns empty array' do
        expect(storage.files_at('not_valid')).to be_empty
      end
    end

    context 'when path is a subdirectory' do
      it 'returns all files in subdirectory' do
        expect(
          storage.files_at('trade_card/original')
        ).to contain_exactly('trade_card/original/front.tif', 'trade_card/original/back.tif')
      end
    end

    context 'when path contains files' do
      it 'returns all files (ignoring nested files)' do
        expect(storage.files_at('')).to contain_exactly('bell.wav', 'dummy.pdf', 'video.mov')
      end

      it 'ignores any dotfiles' do
        expect(storage.files_at('')).not_to include('.example-dotfile')
      end
    end

    context 'when path is partial valid path' do
      it 'return empty array' do
        expect(storage.files_at('tra')).to be_empty
      end
    end

    context 'when path contains only directories' do
      it 'returns empty array' do
        expect(storage.files_at('trade_card')).to be_empty
      end
    end

    context 'when path contains a filename' do
      it 'returns the filename' do
        expect(
          storage.files_at('trade_card/original/front.tif')
        ).to contain_exactly('trade_card/original/front.tif')
      end
    end
  end

  describe '#modify_path' do
    it 'returns acceptable path' do
      expect(storage.modify_path('/test')).to eq('test/')
    end

    it 'does not modify end of path when filename is present' do
      expect(storage.modify_path('/test.jpg')).to eq('test.jpg')
    end
  end

  describe '.valid?' do
    context 'when invalid storage name' do
      it 'returns false' do
        expect(described_class.valid?('invalid')).to be false
      end
    end

    context 'when invalid configuration' do
      before do
        Settings.merge!(working_storage: { new: { bucket: 'something' } })
      end

      after { Settings.reload! }

      it 'returns false' do
        expect(described_class.valid?('new')).to be false
      end
    end
  end
end
