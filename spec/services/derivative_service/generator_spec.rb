# frozen_string_literal: true

describe DerivativeService::Generator do
  describe '.for' do
    let(:file) { Tempfile.new }

    context 'when mime_type not supported' do
      let(:mime_type) { 'application/pdf' }

      it 'returns Generator::Default' do
        expect(described_class.for(file, mime_type)).to be_a DerivativeService::Generator::Default
      end
    end

    context 'when mime_type is supported by image generator' do
      let(:mime_type) { 'image/tiff' }

      it 'returns Generator::Image' do
        expect(described_class.for(file, mime_type)).to be_a DerivativeService::Generator::Image
      end
    end
  end
end