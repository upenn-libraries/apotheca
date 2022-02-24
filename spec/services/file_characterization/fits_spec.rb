# frozen_string_literal: true

describe FileCharacterization::Fits do
  describe '.new' do
    subject { FileCharacterization::Fits.new(Settings.fits.url) }

    it { is_expected.to be_a FileCharacterization::Fits }

    it 'sets url' do
      expect(subject.url).to eql Settings.fits.url
    end
  end

  describe '#examine' do
    let(:fits) { FileCharacterization::Fits.new(Settings.fits.url) }
    let(:file) { file_fixture('files/front.jpeg') }
    let(:technical_metadata) { '' }

    it 'returns technical metadata' do
      expect(file.examine(file: file)).to eql technical_metadata
    end
  end
end