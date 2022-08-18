# frozen_string_literal: true

require_relative 'concerns/modification_details_change_set'

describe ItemChangeSet do
  let(:resource) { build(:item_resource) }
  let(:change_set) { described_class.new(resource) }

  it_behaves_like 'a ModificationDetailsChangeSet'
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

  it 'requires title' do
    change_set.validate(descriptive_metadata: { title: [] })

    expect(change_set.valid?).to be false
    expect(change_set.errors[:'descriptive_metadata.title']).to include 'can\'t be blank'
  end

  it 'requires an ARK' do
    change_set.validate(alternate_ids: [])

    expect(change_set.valid?).to be false
    expect(change_set.errors[:alternate_ids]).to include 'must include an ARK'
  end

  it 'raises an error if more than one ARK is present' do
    change_set.validate(alternate_ids: ['ark:/something', 'ark:/something_else'])

    expect(change_set.valid?).to be false
    expect(change_set.errors[:alternate_ids]).to include 'can only include one ARK'
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
    before do
      change_set.validate(
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
end
