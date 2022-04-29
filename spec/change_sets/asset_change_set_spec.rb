# frozen_string_literal: true

describe AssetChangeSet do
  let(:resource) { AssetResource.new }
  let(:change_set) { described_class.new(resource) }

  # it_behaves_like "a Valkyrie::ChangeSet"

  it 'requires original filename' do
    expect(change_set.valid?).to be false
    expect(change_set.errors.key?(:original_filename)).to be true
    expect(change_set.errors[:original_filename]).to include 'can\'t be blank'
  end

  context 'when mass assigning technical metadata' do
    before do
      change_set.validate(
        original_filename: 'front.jpg',
        technical_metadata: { mime_type: 'text/plain', size: 12_345 }
      )
    end

    it 'is valid' do
      expect(change_set.valid?).to be true
    end

    it 'sets mimetype' do
      expect(change_set.technical_metadata.mime_type).to eql 'text/plain'
    end

    it 'sets size' do
      expect(change_set.technical_metadata.size).to be 12_345
    end
  end

  context 'when mass assigning descriptive metadata' do
    before do
      change_set.validate(
        original_filename: 'front.jpg',
        descriptive_metadata: { label: 'First Page', annotations: [{ text: 'Special Image' }] }
      )
    end

    it 'is valid' do
      expect(change_set.valid?).to be true
    end

    it 'sets label' do
      expect(change_set.descriptive_metadata.label).to eql 'First Page'
    end

    it 'sets annotation' do
      expect(change_set.descriptive_metadata.annotations[0].text).to eql 'Special Image'
    end
  end

  context 'when assigning transcription' do
    context 'with all required fields' do
      before do
        change_set.validate(
          original_filename: 'front.jpg',
          transcriptions: [{ mime_type: 'text/plain', contents: 'Importers' }]
        )
      end

      it 'is valid' do
        expect(change_set.valid?).to be true
      end

      it 'sets transcription mime_type' do
        expect(change_set.transcriptions[0].mime_type).to eql 'text/plain'
      end

      it 'sets transcription contents' do
        expect(change_set.transcriptions[0].contents).to eql 'Importers'
      end
    end

    context 'with missing mime_type' do
      before do
        change_set.validate(
          original_filename: 'front.jpg', transcriptions: [{ contents: 'Importers' }]
        )
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'transcriptions.mime_type']).to include 'can\'t be blank'
      end
    end

    context 'with missing contents' do
      before do
        change_set.validate(
          original_filename: 'front.jpg', transcriptions: [{ mime_type: 'text/plain' }]
        )
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'transcriptions.contents']).to include 'can\'t be blank'
      end
    end
  end

  context 'when updating resource' do
    let(:original_filename) { 'front.jpg' }
    let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister) }
    let(:resource) do
      metadata_adapter.persister.save(resource: AssetResource.new(original_filename: original_filename))
    end

    # Note: Resource must already be created in order to add files.
    context 'when adding a preservation file' do
      let(:preservation_storage) { Valkyrie::StorageAdapter.find(:preservation) }
      let(:preservation_file) do
        preservation_storage.upload(
          file: ActionDispatch::Http::UploadedFile.new(tempfile: File.open(file_fixture('files/front.jpg'))),
          resource: resource,
          original_filename: original_filename
        )
      end

      before do
        change_set.validate(preservation_file_id: preservation_file.id)
      end

      it 'is valid' do
        expect(change_set.valid?).to be true
      end

      it 'sets file ids' do
        expect(change_set.preservation_file_id).to eql preservation_file.id
      end
    end

    # Note: Resource must already be created in order to add files.
    context 'when adding a preservation copy'

    # Note: Resource must already be created in order to add files.
    context 'when adding a derivative' do
      let(:derivative_storage) { Valkyrie::StorageAdapter.find(:derivatives) }
      let(:derivative) do
        derivative_storage.upload(
          file: ActionDispatch::Http::UploadedFile.new(tempfile: File.open(file_fixture('files/front.jpg'))),
          resource: resource,
          original_filename: 'thumbnail'
        )
      end

      before { freeze_time }
      after  { unfreeze_time }

      context 'with valid information' do
        before do
          change_set.validate(
            derivatives: [
              { file_id: derivative.id, mime_type: 'image/jpeg', generated_at: DateTime.current, type: 'thumbnail' }
            ]
          )
        end

        it 'is valid' do
          expect(change_set.valid?).to be true
        end

        it 'sets file_id' do
          expect(change_set.derivatives[0].file_id).to eql derivative.id
        end

        it 'sets mime_type' do
          expect(change_set.derivatives[0].mime_type).to eql 'image/jpeg'
        end

        it 'sets generated_at' do
          expect(change_set.derivatives[0].generated_at).to eql DateTime.current
        end

        it 'sets type' do
          expect(change_set.derivatives[0].type).to eql 'thumbnail'
        end
      end

      context 'with invalid derivative type' do
        before do
          change_set.validate(
            derivatives: [
              { file_id: derivative.id, mime_type: 'image/jpeg', generated_at: DateTime.current, type: 'invalid' }
            ]
          )
        end

        it 'is not valid' do
          expect(change_set.valid?).to be false
          expect(change_set.errors[:'derivatives.type']).to include 'is not included in the list'
        end
      end
    end
  end
end