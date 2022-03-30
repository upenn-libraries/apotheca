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
        technical_metadata: { mime_type: 'text/plain', size: 12345 }
      )
    end

    it 'is valid' do
      expect(change_set.valid?).to be true
    end

    it 'sets mimetype' do
      expect(change_set.technical_metadata.mime_type).to eql 'text/plain'
    end

    it 'sets size' do
      expect(change_set.technical_metadata.size).to be 12345
    end
  end

  context 'when mass assigning descriptive metadata' do
    before do
      change_set.validate(
        original_filename: 'front.jpg',
        descriptive_metadata: { label: 'First Page', annotations: [ { text: 'Special Image' }] }
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

  context 'when updating resource' do
    let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister) }
    let(:resource) do
      metadata_adapter.persister.save(resource: AssetResource.new(original_filename: 'front.jpg'))
    end

    # Note: Resource must already be created in order to add files.
    context 'when adding a preservation copy' do
      it 'sets file id'
    end

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

      before do
        freeze_time
        change_set.validate(
          derivatives: [
            { file_id: derivative.id, mime_type: 'image/jpeg', generated_at: DateTime.current, type: 'thumbnail' }
          ]
        )
      end
      after { unfreeze_time }

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
  end
end