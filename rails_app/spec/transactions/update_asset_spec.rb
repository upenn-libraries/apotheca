# frozen_string_literal: true

describe UpdateAsset do
  shared_examples_for 'does not enqueue jobs' do
    it 'does not enqueue any jobs' do
      expect(GenerateDerivativesJob).not_to have_enqueued_sidekiq_job(any_args)
      expect(PreservationBackupJob).not_to have_enqueued_sidekiq_job(any_args)
    end
  end

  shared_examples_for 'enqueues jobs' do
    it 'enqueues job to generate derivatives and preservation backup' do
      expect(GenerateDerivativesJob).to have_enqueued_sidekiq_job(updated_asset.id.to_s, updated_asset.updated_by)
      expect(PreservationBackupJob).to have_enqueued_sidekiq_job(updated_asset.id.to_s, updated_asset.updated_by)
    end
  end

  describe '#call' do
    let(:transaction) { described_class.new }

    let(:file1) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: File.open(file_fixture('files/trade_card/original/front.tif')),
        filename: 'front.tif'
      )
    end
    let(:file2) do
      ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('files/bell.wav')), filename: 'bell.wav'
    end

    context 'when providing a file for the first time' do
      subject(:updated_asset) { result.value! }

      let(:asset) { persist(:asset_resource) }
      let(:result) do
        transaction.call(id: asset.id, file: file1, label: 'Front of Card', updated_by: 'initiator@example.com')
      end

      include_examples 'enqueues jobs'
      include_examples 'creates a resource event', :update_asset, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'updated label' do
        expect(updated_asset.label).to eql 'Front of Card'
      end

      it 'sets technical metadata' do
        expect(updated_asset.technical_metadata).to include(mime_type: 'image/tiff', size: 291_455,
                                                            duration: nil, width: 400, height: 238,
                                                            md5: 'c2c44072c0ec08013cff72aa7dc8d405')
      end

      it 'sets sha256 checksum' do
        expect(
          updated_asset.technical_metadata.sha256
        ).to eql '0929169032ec29557bf85b05b82923fdb75694393e34f652b8955912376e1e0b'
      end
    end

    context 'when updating file' do
      subject(:updated_asset) { result.value! }

      let(:asset) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup, :with_derivatives) }
      let(:result) do
        transaction.call(
          id: asset.id, file: file2, original_filename: 'bell.wav', label: 'First', updated_by: 'initiator@example.com'
        )
      end

      include_examples 'enqueues jobs'
      include_examples 'creates a resource event', :update_asset, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'updates original filename' do
        expect(updated_asset.original_filename).to eql 'bell.wav'
      end

      it 'updates technical metadata' do
        expect(updated_asset.technical_metadata).to include(mime_type: 'audio/x-wave', size: 30_804,
                                                            duration: 0.17, width: nil, height: nil,
                                                            md5: '79a2f8e83b4babe41ba0b5458e3d1e4a')
      end

      it 'updates preservation_file_id and stores new file' do
        expect(asset.preservation_file_id).not_to eql updated_asset.preservation_file_id
        expect(
          Valkyrie::StorageAdapter.find_by(id: updated_asset.preservation_file_id)
        ).to be_a Valkyrie::StorageAdapter::StreamFile
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

      it 'unlinks and deletes preservation backup' do
        expect(updated_asset.preservation_copies_ids).to be_blank
        expect {
          Valkyrie::StorageAdapter.find_by(id: asset.preservation_copies_ids.first)
        }.to raise_error Valkyrie::StorageAdapter::FileNotFound
      end
    end

    context 'when adding transcriptions' do
      subject(:updated_asset) { result.value! }

      let(:asset) do
        persist(:asset_resource, :with_preservation_file, :with_preservation_backup, :with_derivatives)
      end
      let(:result) do
        transaction.call(
          id: asset.id,
          transcriptions: [
            { mime_type: 'text/plain', contents: 'Importers, 32 S. Howard Street, Baltimore, MD.' }
          ],
          updated_by: 'initiator@example.com'
        )
      end

      include_examples 'does not enqueue jobs'
      include_examples 'creates a resource event', :update_asset, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'updates transcriptions' do
        expect(updated_asset.transcriptions.count).to be 1
        expect(updated_asset.transcriptions.first.contents).to eql 'Importers, 32 S. Howard Street, Baltimore, MD.'
      end
    end

    context 'when preservation file does not have original filename' do
      # File that does not respond to original_filename
      let(:file1) do
        ActionDispatch::Http::UploadedFile.new tempfile: file_fixture('files/trade_card/original/front.tif').open
      end
      let(:asset) { persist(:asset_resource) }
      let(:result) do
        transaction.call(id: asset.id, file: file1, label: 'Front of Card', updated_by: 'initiator@example.com')
      end

      include_examples 'does not enqueue jobs'

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :no_original_filename
      end
    end

    context 'when preservation file has an unsupported file extension' do
      # File with unsupported file extension
      let(:file1) do
        ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('imports/bulk_import_data.csv')),
                                               filename: 'bulk_import_data.csv'
      end
      let(:asset) { persist(:asset_resource) }
      let(:result) do
        transaction.call(id: asset.id, file: file1, updated_by: 'initiator@example.com')
      end

      include_examples 'does not enqueue jobs'

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :invalid_file_extension
      end
    end

    context 'when expected_checksum does not match ingested file' do
      let(:asset) { persist(:asset_resource) }
      let(:result) do
        transaction.call(id: asset.id, file: file1, expected_checksum: '1234', updated_by: 'initiator@example.com')
      end

      include_examples 'does not enqueue jobs'

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :expected_checksum_does_not_match
      end
    end

    context 'when asset update fails' do
      let(:asset) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup, :with_derivatives) }
      let(:result) { transaction.call(id: asset.id, file: file1, updated_by: 'initiator@example.com') }

      before do
        step_double = instance_double(Steps::Validate)
        allow(Steps::Validate).to receive(:new).and_return(step_double)
        allow(step_double).to receive(:call) do |change_set|
          Dry::Monads::Failure.new(error: :step_failed, change_set: change_set)
        end
      end

      include_examples 'does not enqueue jobs'

      it 'cleans up the uploaded file' do
        expect(result.failure[:change_set].preservation_file_id).not_to be_nil
        expect {
          Valkyrie::StorageAdapter.find_by(id: result.failure[:change_set].preservation_file_id)
        }.to raise_error Valkyrie::StorageAdapter::FileNotFound
      end

      it 'does not delete derivatives' do
        result.failure[:change_set].derivatives.each do |d|
          expect(Valkyrie::StorageAdapter.find_by(id: d.file_id)).to be_a Valkyrie::StorageAdapter::StreamFile
        end
      end
    end

    context 'when preservation file has an invalid mime_type' do
      let(:asset) { persist(:asset_resource) }
      let(:result) do
        transaction.call(id: asset.id, file: file1, updated_by: 'test@example.com')
      end

      before do
        metadata = instance_double(FileCharacterization::Fits::Metadata)
        allow(FileCharacterization::Fits::Metadata).to receive(:new).and_return(metadata)
        allow(metadata).to receive(:mime_type).and_return('text/plain')
      end

      include_examples 'does not enqueue jobs'

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :invalid_mime_type
      end
    end

    context 'when skipping preservation backup' do
      subject(:updated_asset) { result.value! }

      before { Settings.skip_preservation_backup = true }
      after { Settings.skip_preservation_backup = false }

      let(:asset) { persist(:asset_resource) }
      let(:result) do
        transaction.call(id: asset.id, file: file1, label: 'Front of Card', updated_by: 'initiator@example.com')
      end

      include_examples 'creates a resource event', :update_asset, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'adds file' do
        expect(updated_asset.preservation_file_id).not_to be_blank
      end

      it 'enqueues derivative job' do
        expect(GenerateDerivativesJob).to have_enqueued_sidekiq_job(updated_asset.id.to_s, updated_asset.updated_by)
      end

      it 'does not enqueue preservation backup' do
        expect(PreservationBackupJob).not_to have_enqueued_sidekiq_job(any_args)
      end
    end

    context 'when generating derivatives synchronously' do
      subject(:updated_asset) { result.value! }

      let(:transaction) { described_class.new.with_step_args(generate_derivatives: [skip: false]) }
      let(:asset) { persist(:asset_resource) }
      let(:result) do
        transaction.call(id: asset.id, file: file1, updated_by: 'initiator@example.com')
      end

      context 'when transaction successful' do
        include_examples 'creates a resource event', :update_asset, 'initiator@example.com', true do
          let(:resource) { updated_asset }
        end

        it 'generates derivatives' do
          expect(updated_asset.derivatives.count).to be 2
        end

        it 'does not enqueue job generate derivatives' do
          expect(GenerateDerivativesJob).not_to have_enqueued_sidekiq_job(any_args)
        end

        it 'enqueues job to run preservation backup' do
          expect(PreservationBackupJob).to have_enqueued_sidekiq_job(updated_asset.id.to_s, updated_asset.updated_by)
        end
      end

      context 'when transaction returns a failure' do
        before do
          step_double = instance_double(Steps::Validate)
          allow(Steps::Validate).to receive(:new).and_return(step_double)
          allow(step_double).to receive(:call) do |change_set|
            Dry::Monads::Failure.new(error: :step_failed, change_set: change_set)
          end
        end

        it 'created derivatives' do
          expect(result.failure[:change_set].derivatives.count).to be 2
        end

        it 'cleans up the derivative files' do
          result.failure[:change_set].derivatives.each do |d|
            expect {
              Valkyrie::StorageAdapter.find_by(id: d.file_id)
            }.to raise_error Valkyrie::StorageAdapter::FileNotFound
          end
        end
      end

      context 'with ocr_language' do
        subject(:updated_asset) { result.value! }

        let(:transaction) { described_class.new.with_step_args(generate_derivatives: [skip: false]) }
        let(:asset) { persist(:asset_resource) }
        let(:result) do
          transaction.call(id: asset.id, file: file1, updated_by: 'initiator@example.com', ocr_language: %w[eng fra])
        end

        it 'generates ocr derivatives' do
          expect(updated_asset.derivatives.count).to be 5
          expect(updated_asset.derivatives.map(&:type)).to contain_exactly('access', 'thumbnail', 'text',
                                                                           'textonly_pdf', 'hocr')
        end
      end
    end
  end
end
