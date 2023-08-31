# frozen_string_literal: true

describe DockerSecrets do
  describe '.lookup' do
    it 'raises an exception for blank keys' do
      expect {
        described_class.lookup('')
      }.to raise_error(DockerSecrets::InvalidKeyError, /Lookup key is blank/)
    end

    it 'returns default when key not present' do
      expect(described_class.lookup('something_secret', 'password')).to eql 'password'
    end
  end

  describe '.lookup!' do
    it 'raises an exception when key not present' do
      expect {
        described_class.lookup!('something_secret')
      }.to raise_error(DockerSecrets::InvalidKeyError, /Docker secret not found for/)
    end
  end
end
