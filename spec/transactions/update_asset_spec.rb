# frozen_string_literal: true

describe UpdateAsset do
  describe '#call' do
    let(:transaction) { described_class.new }
    let(:asset) { persist(:asset_resource) }

    let(:file1) { ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('files/front.jpg')) }
    let(:file2) { ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('files/bell.wav')) }

    context 'when providing a file for the first time' do
      subject(:updated_asset) { result.value! }

      let(:result) do
        transaction.call(
          id: asset.id,
          file: file1,
          label: 'Front of Card',
          updated_by: 'test@example.com'
        )
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'updated label' do
        expect(updated_asset.label).to eql 'Front of Card'
      end

      it 'sets technical metadata' do
        expect(updated_asset.technical_metadata.mime_type).to eql 'image/jpeg'
        expect(updated_asset.technical_metadata.size).to be 42_421
        expect(updated_asset.technical_metadata.md5).to eql 'a93d8dc6bc83cd51ad60a151a8ce11e4'
      end

      it 'sets sha256 checksum' do
        expect(
          updated_asset.technical_metadata.sha256
        ).to eql 'd58516c7d3ece4d79f0de3a649a090af2174e67b7658f336a027a42123a2da72'
      end

      it 'enqueues job to generate derivatives' do
        expect(GenerateDerivativesJob).to have_been_enqueued.with(updated_asset.id.to_s)
      end

      it 'enqueues job to backup preservation file' do
        expect(PreservationBackupJob).to have_been_enqueued.with(updated_asset.id.to_s)
      end
    end

    context 'when updating file' do
      subject(:updated_asset) { result.value! }

      let(:result) do
        transaction.call(
          id: asset.id,
          file: file2,
          original_filename: 'bell.wav',
          label: 'First',
          updated_by: 'test@example.com'
        )
      end

      before do
        transaction.call(
          id: asset.id,
          file: file1,
          label: 'Front of Card',
          updated_by: 'test@example.com'
        )
        GenerateDerivatives.new.call(id: asset.id)
        PreservationBackup.new.call(id: asset.id)
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'updates original filename' do
        expect(updated_asset.original_filename).to eql 'bell.wav'
      end

      it 'updates technical metadata' do
        expect(updated_asset.technical_metadata.mime_type).to eql 'audio/x-wave'
        expect(updated_asset.technical_metadata.size).to be 30_804
        expect(updated_asset.technical_metadata.md5).to eql '79a2f8e83b4babe41ba0b5458e3d1e4a'
      end

      it 'updates checksum' do
        expect(
          updated_asset.technical_metadata.sha256
        ).to eql '16c93ccb293cf3ea20fee8df210ac351365322745a6d626638d091dfc52f200e'
      end

      it 'marks derivatives as stale' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.all?(&:stale)).to be true
      end

      it 'removes preservation backup' do
        expect(updated_asset.preservation_copies_ids).to be_blank
      end

      it 'enqueues job to generate derivatives twice' do
        expect(GenerateDerivativesJob).to have_been_enqueued.with(updated_asset.id.to_s).exactly(:twice)
      end

      it 'enqueues job to backup preservation file twice' do
        expect(PreservationBackupJob).to have_been_enqueued.with(updated_asset.id.to_s).exactly(:twice)
      end
    end

    context 'when adding transcriptions' do
      subject(:updated_asset) { result.value! }

      let(:result) do
        transaction.call(
          id: asset.id,
          transcriptions: [
            mime_type: 'text/plain',
            contents: 'Importers, 32 S. Howard Street, Baltimore, MD.'
          ],
          updated_by: 'test@example.com'
        )
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'updates transcriptions' do
        expect(updated_asset.transcriptions.count).to be 1
        expect(updated_asset.transcriptions.first.contents).to eql 'Importers, 32 S. Howard Street, Baltimore, MD.'
      end

      it 'does not enqueue and jobs' do
        expect(GenerateDerivativesJob).to have_been_enqueued.with(updated_asset.id.to_s).exactly(0)
        expect(PreservationBackupJob).to have_been_enqueued.with(updated_asset.id.to_s).exactly(0)
      end
    end
  end
end
