# frozen_string_literal: true

describe DerivativeService::DerivativeFile do
  describe '.new' do
    context 'when no file is provided' do
      it 'creates a temp file' do
        derivative_file = described_class.new(mime_type: 'text/plain')
        expect(derivative_file.file).to be_a(Tempfile)
      end
    end
  end

  describe '#cleanup!' do
    context 'with a Tempfile' do
      it 'removes file and sets file attribute to nil' do
        derivative_file = described_class.new(mime_type: 'text/plain')
        file_path = derivative_file.path
        derivative_file.cleanup!
        expect(File.exist?(file_path)).to be false
        expect(derivative_file.file).to be_nil
      end
    end

    context 'with a File' do
      it 'removes file and sets file attribute to nil' do
        derivative_file = described_class.new(file: File.new('test.txt', 'w'), mime_type: 'text/plain')
        file_path = derivative_file.path
        derivative_file.cleanup!
        expect(File.exist?(file_path)).to be false
        expect(derivative_file.file).to be_nil
      end
    end
  end
end
