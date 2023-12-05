# frozen_string_literal: true

require_relative 'concerns/modification_details_change_set'
require_relative 'concerns/lockable_change_set'

describe ItemChangeSet do
  let(:resource) { build(:item_resource) }
  let(:change_set) { described_class.new(resource) }

  it_behaves_like 'a ModificationDetailsChangeSet'
  it_behaves_like 'a LockableChangeSet', described_class
  # it_behaves_like "a Valkyrie::ChangeSet"

  it 'requires human readable name' do
    change_set.validate(human_readable_name: nil)

    expect(change_set.valid?).to be false
    expect(change_set.errors[:human_readable_name]).to include 'can\'t be blank'
  end

  it 'sets published to default' do
    expect(change_set.published).to be false
  end

  it 'sets first_published_at' do
    date = DateTime.new(2000, 1, 1)
    change_set.validate(first_published_at: date)

    expect(change_set.first_published_at).to eql date
  end

  it 'sets last_published_at' do
    date = DateTime.current
    change_set.validate(last_published_at: date)

    expect(change_set.last_published_at).to eql date
  end

  it 'requires published' do
    change_set.validate(published: nil)

    expect(change_set.valid?).to be false
    expect(change_set.errors[:published]).to include 'is not included in the list'
  end

  it 'requires title if bibnumber is not set' do
    change_set.validate(descriptive_metadata: { title: [] })

    expect(change_set.valid?).to be false
    expect(change_set.errors[:'descriptive_metadata.title']).to include 'can\'t be blank'
  end

  it 'does not require title if bibnumber is set' do
    change_set.validate(descriptive_metadata: { title: [], bibnumber: [{ value: '123456789' }] })
    expect(change_set.valid?).to be true
  end

  it 'requires unique identifier to be an ARK' do
    change_set.validate(unique_identifier: 'invalid')

    expect(change_set.valid?).to be false
    expect(change_set.errors[:unique_identifier]).to include 'must be an ARK'
  end

  context 'when mass assigning structural metadata' do
    let(:resource) { build(:item_resource, :with_asset) }

    context 'with valid attributes' do
      before do
        change_set.validate(
          structural_metadata: {
            viewing_direction: 'left-to-right',
            viewing_hint: 'paged',
            arranged_asset_ids: [resource.asset_ids.first]
          }
        )
      end

      it 'is valid' do
        expect(change_set.valid?).to be true
      end

      it 'sets viewing direction' do
        expect(change_set.structural_metadata.viewing_direction).to eql 'left-to-right'
      end

      it 'sets viewing hint' do
        expect(change_set.structural_metadata.viewing_hint).to eql 'paged'
      end
    end

    it 'requires valid viewing hint' do
      change_set.validate(structural_metadata: { viewing_hint: 'invalid' })

      expect(change_set.valid?).to be false
      expect(change_set.errors[:'structural_metadata.viewing_hint']).to contain_exactly 'is not included in the list'
    end

    it 'requires valid viewing direction' do
      change_set.validate(structural_metadata: { viewing_direction: 'invalid' })

      expect(change_set.valid?).to be false
      expect(
        change_set.errors[:'structural_metadata.viewing_direction']
      ).to contain_exactly 'is not included in the list'
    end

    context 'with invalid arranged_asset_ids' do
      before do
        change_set.validate(structural_metadata: { arranged_asset_ids: ['random-invalid-id'] })
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(
          change_set.errors[:'structural_metadata.arranged_asset_ids']
        ).to contain_exactly 'are not all included in asset_ids'
      end
    end
  end

  context 'when mass assigning descriptive metadata' do
    let(:metadata) { change_set.descriptive_metadata }

    context 'with valid data' do
      before do
        change_set.validate(
          descriptive_metadata: {
            title: [{ value: 'Some Great Item' }],
            date: [{ value: '2022-02-02' }],
            name: [
              {
                value: 'Random, Person',
                uri: 'https://example.com/random-person',
                role: [{ value: 'creator' }]
              }
            ]
          }
        )
      end

      it 'is valid' do
        expect(change_set.valid?).to be true
      end

      it 'sets title' do
        expect(metadata.title.pluck(:value)).to match_array 'Some Great Item'
      end

      it 'sets date' do
        expect(metadata.date.pluck(:value)).to match_array '2022-02-02'
      end

      it 'sets name' do
        expect(metadata.name.first.value).to eq 'Random, Person'
        expect(metadata.name.first.uri).to eq 'https://example.com/random-person'
      end

      it 'sets role' do
        expect(metadata.name.first.role.first.value).to eq 'creator'
      end

      context 'when removing a value' do
        before do
          change_set.validate(
            descriptive_metadata: { name: [] }
          )
        end

        it 'removes names' do
          expect(metadata.name).to be_blank
        end

        it 'keeps title' do
          expect(metadata.title.length).to be 1
        end
      end
    end

    context 'with invalid data' do
      before do
        change_set.validate(
          descriptive_metadata: {
            subject: [{ uri: 'https://example.com/unicorn' }],
            name: [{ uri: 'https://example.com/random-person', role: [{ uri: 'https://example.com/creator' }] }]
          }
        )
      end

      it 'adds expected error for subject' do
        expect(change_set.errors[:'descriptive_metadata.subject']).to contain_exactly('missing value')
      end

      it 'adds expected errors for name' do
        expect(
          change_set.errors[:'descriptive_metadata.name']
        ).to contain_exactly('missing value', 'role missing value')
      end
    end

    context 'with empty values' do
      before do
        change_set.validate(
          descriptive_metadata: {
            title: [{ value: 'Some Great Item' }],
            date: [{ value: '' }],
            name: [
              {
                value: '',
                uri: '',
                role: [{ value: '' }]
              }
            ]
          }
        )
      end

      it 'removes blank date values' do
        expect(metadata.date).to be_blank
      end

      it 'removes name values' do
        expect(metadata.name).to be_blank
      end
    end
  end

  context 'with asset ids' do
    let(:resource) { build(:item_resource, :with_asset) }

    it 'requires a thumbnail asset id' do
      change_set.validate(thumbnail_asset_id: nil)

      expect(change_set.valid?).to be false
      expect(change_set.errors[:thumbnail_asset_id]).to include 'can\'t be blank'
    end

    it 'requires valid thumbnail_asset_id' do
      change_set.validate(thumbnail_asset_id: 'random-invalid-id')

      expect(change_set.valid?).to be false
      expect(change_set.errors[:thumbnail_asset_id]).to include 'is not included in asset_ids'
    end
  end

  # NOTE: Resource must already be created in order to add files.
  context 'when adding a derivative' do
    let(:resource) { persist(:item_resource, :with_asset) }
    let(:derivative_storage) { Valkyrie::StorageAdapter.find(:iiif_manifests) }
    let(:derivative) do
      derivative_storage.upload(
        file: ActionDispatch::Http::UploadedFile.new(tempfile: file_fixture('iiif_manifest/base_item.json').open),
        resource: resource,
        original_filename: 'iiif_manifest'
      )
    end

    before { freeze_time }

    after  { unfreeze_time }

    context 'with valid information' do
      before do
        change_set.validate(
          derivatives: [
            { file_id: derivative.id, mime_type: 'application/json',
              generated_at: DateTime.current, type: 'iiif_manifest' }
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
        expect(change_set.derivatives[0].mime_type).to eql 'application/json'
      end

      it 'sets generated_at' do
        expect(change_set.derivatives[0].generated_at).to eql DateTime.current
      end

      it 'sets type' do
        expect(change_set.derivatives[0].type).to eql 'iiif_manifest'
      end
    end

    context 'with invalid derivative type' do
      before do
        change_set.validate(
          derivatives: [
            { file_id: derivative.id, mime_type: 'application/json', generated_at: DateTime.current, type: 'access' }
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
