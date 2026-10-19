# frozen_string_literal: true

describe IIIFImageAPI do
  let(:api) { described_class.new('1234') }

  describe '#base_url' do
    context 'with default options' do
      it 'returns expected url' do
        expect(api.base_url).to eql 'http://localhost:8182/iiif/3/1234'
      end
    end

    context 'with version specified' do
      let(:api) { described_class.new('1234', version: 2) }

      it 'returns expected url' do
        expect(api.base_url).to eql 'http://localhost:8182/iiif/2/1234'
      end
    end
  end

  describe '#info_url' do
    it 'returns expected url' do
      expect(api.info_url).to eql 'http://localhost:8182/iiif/3/1234/info.json'
    end
  end

  describe '#image_url' do
    context 'with default options' do
      it 'returns expected url' do
        expect(api.image_url).to eql 'http://localhost:8182/iiif/3/1234/full/max/0/default.jpg'
      end
    end

    context 'with size specified' do
      it 'returns expected url' do
        expect(api.image_url(size: '300,')).to eql 'http://localhost:8182/iiif/3/1234/full/300,/0/default.jpg'
      end
    end
  end
end
