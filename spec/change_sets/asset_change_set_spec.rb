# frozen_string_literal: true

require_relative 'concerns/modification_details_change_set'

describe AssetChangeSet do
  let(:resource) { build(:asset_resource) }
  let(:change_set) { described_class.new(resource) }

  it_behaves_like 'a ModificationDetailsChangeSet'
  # it_behaves_like 'a Valkyrie::ChangeSet'

  it 'sets label' do
    change_set.validate(label: 'First Page')

    expect(change_set.label).to eql 'First Page'
  end

  it 'sets annotations' do
    change_set.validate(annotations: [{ text: 'Special Image' }])

    expect(change_set.annotations[0].text).to eql 'Special Image'
  end

  it 'does not set annotation if text missing' do
    change_set.validate(annotations: [{ text: nil }])

    expect(change_set.valid?).to be true
    expect(change_set.annotations[0]).to be_nil
  end

  context 'when mass assigning technical metadata' do
    before do
      change_set.validate(
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

  context 'when assigning transcription' do
    context 'with all required fields' do
      before do
        change_set.validate(
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
          transcriptions: [{ contents: 'Importers' }]
        )
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'transcriptions.mime_type']).to include 'can\'t be blank'
      end
    end

    context 'when invalid mime type' do
      before do
        change_set.validate(
          transcriptions: [{ mime_type: 'text/html', contents: 'Importers' }]
        )
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'transcriptions.mime_type']).to include 'is not included in the list'
      end
    end

    context 'with missing contents' do
      before do
        change_set.validate(transcriptions: [{ mime_type: 'text/plain' }])
      end

      it 'it does not set transcription value' do
        expect(change_set.valid?).to be true
        expect(change_set.transcriptions[0]).to be_nil
      end
    end
  end

  # NOTE: Resource must already be created in order to add files.
  context 'when adding a preservation file' do
    let(:resource) { persist(:asset_resource) }
    let(:preservation_storage) { Valkyrie::StorageAdapter.find(:preservation) }
    let(:preservation_file) do
      preservation_storage.upload(
        file: ActionDispatch::Http::UploadedFile.new(tempfile: File.open(file_fixture('files/front.tif'))),
        resource: resource,
        original_filename: resource.original_filename
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

    it 'requires original filename' do
      change_set.validate(original_filename: nil)

      expect(change_set.valid?).to be false
      expect(change_set.errors[:original_filename]).to include 'can\'t be blank'
    end
  end

  # NOTE: Resource must already be created in order to add files.
  context 'when adding a preservation copy' do
    let(:resource) { persist(:asset_resource, :with_preservation_file) }
    let(:preservation_copy_storage) { Valkyrie::StorageAdapter.find(:preservation_copy) }
    let(:preservation_copy_file) do
      preservation_copy_storage.upload(
        file: ActionDispatch::Http::UploadedFile.new(tempfile: File.open(file_fixture('files/front.tif'))),
        resource: resource,
        original_filename: resource.original_filename
      )
    end

    before do
      change_set.validate(preservation_copies_ids: [preservation_copy_file.id])
    end

    it 'is valid' do
      expect(change_set.valid?).to be true
    end

    it 'sets file ids' do
      expect(change_set.preservation_copies_ids).to contain_exactly preservation_copy_file.id
    end
  end

  # NOTE: Resource must already be created in order to add files.
  context 'when adding a derivative' do
    let(:resource) { persist(:asset_resource, :with_preservation_file) }
    let(:derivative_storage) { Valkyrie::StorageAdapter.find(:derivatives) }
    let(:derivative) do
      derivative_storage.upload(
        file: ActionDispatch::Http::UploadedFile.new(tempfile: File.open(file_fixture('files/front.tif'))),
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
