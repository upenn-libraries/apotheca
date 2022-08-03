# frozen_string_literal: true

describe ItemChangeSet do
  let(:resource) { ItemResource.new }
  let(:change_set) { described_class.new(resource) }

  # it_behaves_like "a Valkyrie::ChangeSet"

  it 'requires human readable name' do
    change_set.validate(human_readable_name: nil)

    expect(change_set.valid?).to be false
    expect(change_set.errors.key?(:human_readable_name)).to be true
    expect(change_set.errors[:human_readable_name]).to include 'can\'t be blank'
  end

  it 'sets published to default' do
    expect(change_set.published).to be false
  end

  it 'requires published' do
    change_set.validate(published: nil)

    expect(change_set.valid?).to be false
    expect(change_set.errors.key?(:published)).to be true
    expect(change_set.errors[:published]).to include 'is not included in the list'
  end

  context 'when mass assigning structural metadata' do
    before do
      change_set.validate(
        descriptive_metadata: { title: ['New Item'] },
        human_readable_name: 'New Item',
        asset_ids: ['first-asset-id'],
        thumbnail_id: 'first-asset-id'
      )
    end

    context 'with valid attributes' do
      before do
        change_set.validate(
          structural_metadata: {
            viewing_direction: 'left-to-right',
            viewing_hint: 'paged',
            arranged_asset_ids: ['first-asset-id']
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

    context 'with invalid viewing hint' do
      before do
        change_set.validate(structural_metadata: { viewing_hint: 'invalid' })
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'structural_metadata.viewing_hint']).to contain_exactly 'is not included in the list'
      end
    end

    context 'with invalid viewing direction' do
      before do
        change_set.validate(structural_metadata: { viewing_direction: 'invalid' })
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'structural_metadata.viewing_direction']).to contain_exactly 'is not included in the list'
      end
    end

    context 'with invalid arranged_asset_ids' do
      before do
        change_set.validate(structural_metadata: { arranged_asset_ids: ['random-invalid-id'] })
      end

      it 'is not valid' do
        expect(change_set.valid?).to be false
        expect(change_set.errors[:'structural_metadata.arranged_asset_ids']).to contain_exactly 'are not all included in asset_ids'
      end
    end
  end

  context 'when mass assigning descriptive metadata' do
    before do
      change_set.validate(
        human_readable_name: 'New Item',
        descriptive_metadata: { title: ['Some Great Item'], date: ['2022-02-02'] }
      )
    end

    it 'is valid' do
      expect(change_set.valid?).to be true
    end

    it 'sets title' do
      expect(change_set.descriptive_metadata.title).to match_array 'Some Great Item'
    end

    it 'sets date' do
      expect(change_set.descriptive_metadata.date).to match_array '2022-02-02'
    end
  end

  context 'with asset ids' do
    let(:asset) do
      asset_change_set = AssetChangeSet.new(AssetResource.new)
      asset_change_set.validate(original_filename: 'front.jpg')
      asset_change_set.sync
    end

    before do
      change_set.validate(
        human_readable_name: 'New Item',
        asset_ids: [asset.id],
        descriptive_metadata: { title: ['Some Great Item'] }
      )
    end

    it 'requires a thumbnail id' do
      expect(change_set.valid?).to be false
      expect(change_set.errors.key?(:thumbnail_id)).to be true
      expect(change_set.errors[:thumbnail_id]).to include 'can\'t be blank'
    end

    context 'when invalid thumbnail_id present' do
      before do
        change_set.validate(thumbnail_id: 'random-invalid-id')
      end

      it 'returns validation error' do
        expect(change_set.valid?).to be false
        expect(change_set.errors.key?(:thumbnail_id)).to be true
        expect(change_set.errors[:thumbnail_id]).to include 'is not included in asset_ids'
      end
    end


  end
end