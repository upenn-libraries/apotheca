# frozen_string_literal: true

describe DerivativeResource do
  describe '#extension' do
    it 'returns expected extension for audio derivative' do
      expect(described_class.new(mime_type: 'audio/mpeg').extension).to be 'mp3'
    end

    it 'returns expected extension for video derivative' do
      expect(described_class.new(mime_type: 'video/mp4').extension).to be 'mp4'
    end
  end
end
